[pathstr, ~, ~] = fileparts(mfilename('fullpath'));
addpath(genpath(pathstr));
addpath(genpath(fullfile(pathstr, '../lfuf')));
clear 'pathstr'