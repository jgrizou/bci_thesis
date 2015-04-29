[pathstr, ~, ~] = fileparts(mfilename('fullpath'));
addpath(genpath(pathstr));
addpath(genpath(fullfile(pathstr, '../lfui')));
addpath(genpath(fullfile(pathstr, '../matlab_tools')));
clear 'pathstr'