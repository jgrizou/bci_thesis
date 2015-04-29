init
[pathstr, ~, ~] = fileparts(mfilename('fullpath'));
warning('off', 'ensure_positive_semidefinite:NegativeEigenvalues')
warning('off', 'ensure_symmetry:ComplexInfNaN')
warning('off', 'process_options:argUnused')
warning('off', 'cross_validation:NotEnoughData')

% We choose to use a Logger as a kind of workspace to store and retrieve usefull variable
% It also allow to easilly creates history of data and retrieve then as easilly
% You may get confuse at first but compare this file with the
% demo_no_recorder to see the benefit of it
% rec is the only short name variable that you should see and stand for
% recorder, a Logger instance.
rec = Logger();

%% shuffle random seed according to current time
seed = init_random_seed(); % init seed with current time
rec.log_field('randomSeed', seed);

%% Environement
% set-up world
gSize = 5;
environment = Discrete_mdp_gridworld(gSize);
environment.set_state(randi(environment.nS));
rec.logit(environment)

% generate task hypothesis
% hytothesis are represented as optimal policies
nStates = environment.nS;
nHypothesis = environment.nS;
hypothesisPolicies = cell(1, nHypothesis);
for iHyp = 1:nHypothesis
    tmpEnvironment = Discrete_mdp_gridworld(environment.gSize);
    tmpR = zeros(nStates, 1);
    tmpR(iHyp) = 1; % sparse reward function, zero everywhere but 1 on a randomly selected state
    tmpEnvironment.set_reward(tmpR);
    [~, hypothesisPolicies{iHyp}] = VI(tmpEnvironment);
end
rec.logit(nHypothesis)
rec.logit(hypothesisPolicies)

hypothesisRecordNames = cell(1, rec.nHypothesis);
for iHyp = 1:rec.nHypothesis
    hypothesisRecordNames{iHyp} = ['plabelHyp', num2str(iHyp)];
end
rec.logit(hypothesisRecordNames)

%% Learner side
% choose which frames of interaction the learner uses
rec.log_field('learnerFrame',Discrete_mdp_feedback_frame(0.1)) % learner believes teacher makes 10% of the times teaching errors

% choose classifier to use
rec.log_field('blankClassifier', @() GaussianUninformativePrior_classifier('shrink', 0.5));

%% TCP communcation protocol
disp('Setting up TCP...')
BCI_IP = 'localhost';
% BCI_IP = '192.168.0.10';
BCI_PORT = 4012;

END_TASK = 200;
BLOCK = 50;

TARGET_REACHED = 99;
TARGET_NOT_REACHED = 0;

tcp = TCP(BCI_IP, BCI_PORT);
tcp.open()

%% Running Variable
% I declare those variable this way to be sure to not use it from the workspace
% Otherwise an other method would be
% nSteps = 100; rec.logit(nSteps)
% it would the same, as you prefer


%% Setup experiment
% I declare those variable this way to be sure to not use it from the workspace
% Otherwise an other method would be
% nSteps = 100; rec.logit(nSteps)

rec.log_field('nInitSteps', 40) %min step before computing stuff
%
actionSelectionInfo = struct;
actionSelectionInfo.method = 'uncertainty'; % main planning method
actionSelectionInfo.initMethod = 'random'; % during init phase
actionSelectionInfo.confidentMethod = 'greedy'; % when target identified go for it
actionSelectionInfo.epsilon = 0; % for e_greedy or e_uncertainty methods
actionSelectionInfo.nStepBetweenUpdate = 1; % recompute planning X every steps
rec.log_field('actionSelectionInfo', actionSelectionInfo)

rec.log_field('uncertaintyMethod', 'signal_sample')
rec.log_field('nSampleUncertaintyPlanning', 20) % use X random sample to compute uncertainty map

rec.log_field('nCrossValidation', 10) % to estimate confusion matrix

rec.log_field('confidenceLevel', 0.9) % when to stop

methodInfo = struct;
methodInfo.classifierMethod = 'online'; % online or calibration
methodInfo.samplingMethod = 'one_shot'; % one-shot or sampling
methodInfo.estimateMethod = 'power_matching';
methodInfo.cumulMethod = 'filter'; % filter or batch
methodInfo.probaMethod = 'pairwise'; % pairwise or normalize
rec.log_field('methodInfo', methodInfo)

%% BCI receive initial state
disp('Waiting for feature and state...')
[features, nextState] = tcp.receive_features_and_state();
rec.environment.set_state(nextState)
disp('Received feature and state.')

%%
iStep = 0;
targetReached = false;
isConfident = false;
while 1
    stepTime = tic;
    iStep = iStep + 1;
    disp('###')
    fprintf('Step %4d\n',iStep);
    rec.logit(iStep)
    
    %% choose and apply action
    state = rec.environment.get_state();
    rec.logit(state)
    
    action = 0;
    while ~is_action_BCI_valid(state, action)
        action = recorder_select_action(rec, rec.methodInfo);
    end
    rec.logit(action)
    
    %BCI send action
    disp('Ready to send action, waiting for signals...')
    block = 0;
    while block ~= BLOCK
        block = tcp.receive(1);
    end
    disp(['Sending action: ', num2str(griz2itu_action(action))])
    tcp.send(griz2itu_action(action), 1)
    
    %% plotting
    if iStep > 2
        clf
        plot_frame_BCI(rec, iStep, rec.methodInfo)
        drawnow
    end
    
    %% BCI receive state, features
    disp('Waiting for feature and state...')
    [features, nextState] = tcp.receive_features_and_state();
    disp('Received feature and state.')
    if nextState == END_TASK
        disp('')
        disp('Experiment terminated')
        disp('')
        break
    end
    
    %outliers
    if max(features) > 20
        disp('********************')
        disp('* OUTLIER DETECTED *')
        disp('*  IGNORING TRIAL  *')
        disp('********************')
        %delog stuff from logger
        % not implemented in logger, so I do it by hand here cause I do not
        % want to modify the Logger class for now
        rec.iStep(end) = [];
        for i = 1:length(rec.fields)
            if strcmp(rec.fields{i}, 'iStep')
                rec.nElementsFields(i) = rec.nElementsFields(i) - 1;
            end
        end
        
        rec.state(end) = [];
        for i = 1:length(rec.fields)
            if strcmp(rec.fields{i}, 'state')
                rec.nElementsFields(i) = rec.nElementsFields(i) - 1;
            end
        end
        
        rec.action(end) = [];
        for i = 1:length(rec.fields)
            if strcmp(rec.fields{i}, 'action')
                rec.nElementsFields(i) = rec.nElementsFields(i) - 1;
            end
        end
        
        % here comes the ugliest part
        iStep = iStep -1;
        
    else
        
        rec.environment.set_state(nextState)
        rec.log_field('teacherSignal', features);
        
        %% compute hypothetic plabels
        hypothesisPLabel = cellfun(@(hyp) rec.learnerFrame.compute_labels(hyp, state, action), rec.hypothesisPolicies, 'UniformOutput', false);
        rec.log_multiple_fields(rec.hypothesisRecordNames, hypothesisPLabel)
        
        %% compute hypothesis probabilities
        recorder_compute_proba(rec, rec.methodInfo)
        
        %% detect confidence
        [isConfident, bestHypothesis] = recorder_check_confidence(rec, rec.methodInfo);
        rec.logit(isConfident)
        rec.logit(bestHypothesis)
        
        targetReached = bestHypothesis == rec.environment.currentState;
        rec.logit(targetReached)
        
        if targetReached
            % reset the learning process
            recorder_reset_proba(rec, bestHypothesis, rec.methodInfo)
            % change which hypothesis is the one taught by the teacher
            teacherHypothesis = randi(rec.nHypothesis); % this will be recorded at each iteration so not now
            teacherPolicy = rec.hypothesisPolicies{teacherHypothesis};
            
            % BCI send target reached information
            disp('$$$$$$')
            disp('Target reached with confidence, waiting for user input.')
            disp('Enter "return", to continue with next target.')
            disp('If you dbquit now, do not forget to save the results.')
            keyboard
            disp('Sending target reached information...')
            tcp.send(TARGET_REACHED, 1)
            disp('Waiting for confirmation...')
            block = 0;
            while block ~= BLOCK
                block = tcp.receive(1);
            end
        end
        
        %% compute uncertainty
        recorder_compute_uncertainty_map(rec, rec.uncertaintyMethod, rec.methodInfo)
        
        %% end loop
        rec.log_field('stepTime', toc(stepTime))
    end
end

%% Saving
disp('Saving...')
folder = fullfile(pathstr, 'results');
if ~exist(folder, 'dir')
    mkdir(folder)
end
recFilename = generate_timestamped_filename(folder, 'mat');
rec.save(recFilename)
disp('Saving raw...')
folder = fullfile(pathstr, 'raw_results');
if ~exist(folder, 'dir')
    mkdir(folder)
end
recFilename = generate_timestamped_filename(folder, 'mat');
rec.save_all_fields(recFilename)


%%
disp('Close TCP...')
tcp.close()
disp('Done.')

