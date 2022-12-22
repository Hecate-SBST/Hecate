clearvars
clc

addpath(genpath('Models'))
eval('SettingWT')

% Count number of blocks
info = sldiagnostics(model,'CountBlocks');
idx_start = strfind(info,'Total blocks : ')+15;
idx_end = find(info(idx_start:end) == newline,1)+idx_start;
n_block = str2double(info(idx_start:idx_end));

% Count number of inports and outport
load_system(model)
search_opt = Simulink.FindOptions('SearchDepth',1);
n_input = length(Simulink.findBlocksOfType(model,'Inport',search_opt));

n_output = length(Simulink.findBlocksOfType(model,'Outport',search_opt));
bool_robOutport = ~isempty(Simulink.findBlocks(model,'Name','Outport_Fit_Hecate'));
n_output = n_output-double(bool_robOutport);

% Count number of levels in the model
subsystemHandles = Simulink.findBlocksOfType(model,'SubSystem');
n_level = 1;
bp_deep = model;
for ii = 1:length(subsystemHandles)
    bp = getfullname(subsystemHandles(ii));
    bp_parts = split(bp,'/');
    check = cellfun(@isempty,bp_parts);
    level_temp = length(bp_parts)-2*sum(check);

    if level_temp > n_level
        n_level = level_temp;
        bp_deep = strrep(bp,newline,' ');
    end

end

% Print model parameters
close_system(model)
fprintf('Model:\t%s\n',model)
fprintf('Number of blocks:\t%i\n',n_block)
fprintf('Number of inports:\t%i\n',n_input)
fprintf('Number of outports:\t%i\n',n_output)
fprintf('Number of levels:\t%i\n',n_level)
fprintf('Simulation time:\t%i\n',simulationTime)
disp(bp_deep)