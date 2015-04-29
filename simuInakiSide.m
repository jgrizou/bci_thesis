[pathstr, ~, ~] = fileparts(mfilename('fullpath'));
addpath(genpath(pathstr));
addpath(genpath(fullfile(pathstr, '../lfui')));
addpath(genpath(fullfile(pathstr, '../matlab_tools')));

%% Environement
% set-up world
gSize = 5;
environment = Discrete_mdp_gridworld(gSize);
environment.set_state(randi(environment.nS));

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

%% generate artificial teaching signals
load(fullfile(pathstr, 's4.mat')) % load X, Y, accuracy
teacherDispatcher = Dispatcher(X, Y, true);

%%
teacherFrame = Discrete_mdp_feedback_frame(0); % no error

%%
disp('Setting up TCP...')
BCI_IP = 'localhost';
BCI_PORT = 4012;

END_TASK = 200;
BLOCK = 50;

TARGET_REACHED = 99;
TARGET_NOT_REACHED = 0;

tcp = TCP(BCI_IP, BCI_PORT);
tcp.f_tcp.NetworkRole = 'server';
disp('Waiting for connection...')
tcp.open()

%%
% choose which hypothesis is the one taught by the teacher
teacherHypothesis = randi(nHypothesis); % this will be recorded at each iteration so not now
teacherPolicy = hypothesisPolicies{teacherHypothesis};

features = teacherDispatcher.get_sample(1);
disp('Ready')
% while 1
for i = 1:50
    %%    
    disp('###')
    fprintf('Teacher target is %d\n', teacherHypothesis)

    disp('Sending feature and state.')
    state = environment.get_state();
    tcp.send_features_and_state(features, state)
    
    pause(2)
    %%
    disp('Sending BLOCK.')
    tcp.send(BLOCK, 1)    
    disp('Waiting for action...')
    action = itu2griz_action(tcp.receive(1));
    environment.apply_action(action);
    
    %% simulate teacher response
    teacherPLabel = teacherFrame.compute_labels(teacherPolicy, state, action);
    teacherLabel = sample_action_discrete_policy(teacherPLabel);
    features = teacherDispatcher.get_sample(teacherLabel);
end
