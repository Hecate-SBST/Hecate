function [test_assessment_path,test_sequence_path] = simConfig(modelname,activeScenarioTA,activeScenarioTS,input_param,modelfcn)
% Simulate the model once and get the block path and set the active
% scenario, of the Test Sequence and Test Assessment blocks and get all
% input signals to the Test Assessment block.
%
%           [test_assessment_path,test_sequence_path] = simConfig(modelname,activeScenarioTA,activeScenarioTS,modelfcn)
%
%   E.g.:   [ta_path,ts_path] = simConfig('vdp','Scenario_1','')
%           [ta_path,ts_path] = simConfig('Autotrans_shift','AT_1','AT_1', @blackbox_AT)
%
% Inputs:
%   modelname: char array containing the name of the model.
%
%   activeScenarioTA: char array containing the name of the active Scenario
%   in the Test Assessment block. If the Test Assessment block does not use
%   Scenarios, then this variable must be an empty char array: ''.
%
%   activeScenarioTS: char array containing the name of the active Scenario
%   in the Test Sequence block. If the Test Sequence block does not use
%   Scenarios, then this variable must be an empty char array: ''.
%
%   input_param: struct array containing information on each Hecate input
%   parameter. It has the fields Name, LowerBound and UpperBound.
%
%   modelfcn (Optional): if the model uses a function to run, it is the
%   function handle.
%
% Outputs:
%   test_assessment_path: char array containing the path to the Test
%   Assessment block.
%
%   test_sequence_path: char array containing the path to the Test Sequence
%   block.

global initCond;
global simulationTime;

% Check that modelfcn is a function handle (if it is given)
if nargin == 5 && ~isa(modelfcn,'function_handle')
    error('The fifth argument of simConfig must be a function handle.')
end

% Close all the systems open in Simulink exept the one we are investigating
loadedModels = Simulink.allBlockDiagrams('model');
modelNames = get_param(loadedModels,'Name');
if ~any(strcmp(modelNames,modelname))
    load_system(modelname)
end

for ii = 1:length(modelNames)
    if isa(modelNames,'char')
        name_temp = modelNames;
    else
        name_temp = modelNames{ii};
    end

    if ~strcmp(name_temp,modelname) && bdIsLoaded(name_temp)
        if ~strcmp(name_temp,'power_utile')
            save_system(name_temp)
        end
        close_system(name_temp)
    
        warning('The model %s was open during the execution of Hecate. For safety, it has been saved and closed.',name_temp)
    end
end

%% Simulate the model

% Check that the time and output are returned as variables to the workspace
% (only for Simulink models, not for function handles)
if ~exist('modelfcn','var')
    timeSave = get_param(modelname,'SaveTime');
    if ~strcmp(timeSave,'on')
        set_param(modelname,'SaveTime','on');
        warning('The model is not saving the time array. The model settings have been changed to return the time array as output of the model.') 
    end

    outputSave = get_param(modelname,'SaveOutput');
    if ~strcmp(outputSave,'on')
        set_param(modelname,'SaveOutput','on');
        warning('The model is not saving the output of the simulation. The model settings have been changed to return the output of the model in the chosen format.') 
    end

    outputFormat = get_param(modelname,'ReturnWorkspaceOutputs');
    if ~strcmp(outputFormat,'on')
        set_param(modelname,'ReturnWorkspaceOutputs','on');
        warning('The model is not returning the simulation results as a single variable. The model settings have been changed accordingly.') 
    end
end

% Generate a random value for Hecate parameters
T_end = simulationTime;
param_temp = zeros(length(input_param),1);
for ii = 1:length(input_param)
    param_temp(ii) = rand(1)*(input_param(ii).UpperBound-input_param(ii).LowerBound)+input_param(ii).LowerBound;
    assignin('base',input_param(ii).Name,param_temp(ii));
end

if ~isempty(initCond)
    x0 = rand(size(initCond,1),1).*(diff(initCond,1,2))+initCond(:,1);
else
    x0 = [];
end

% Simulate the model with a random input and random initial conditions
if exist('modelfcn','var')
    % If the model uses a matlab function to run.
    feval(modelfcn,x0,T_end,[],[]);
else
    % If the model is simulated directly using a Simulink model.
    simopt = simget(modelname);
    if ~isempty(x0)
        simopt = simset(simopt, 'InitialState', XPoint);
    end
    try
        sim(modelname,[0, T_end],simopt);
    catch err
        % If the simulation was interrupted by an assert statement, the
        % system will ignore the error message.
        if ~isa(err,'MSLException') || ~strcmp(err.identifier,'Stateflow:Runtime')
            throw(err)
        end
    end
end

%% Get the path to the active Test Assessment block

% Get the assessment from the Test Assessment block
assSet = sltest.getAssessments(modelname); % get the entire Assessment set
assSet_summary = getSummary(assSet);
if assSet_summary.Total < 1
    error('The Test Assessment block does not contain any assessment.')
end

% Get the blockpath to the test assessment block
as = get(assSet,1); %get FIRST assessment object from the set
test_assessment_path = as.BlockPath.getBlock(1); % Path to Test Assessment block that the assessment object belongs to

% Check that all the active assessments come from the same Test Assessment
% block
for ii = 1:assSet_summary.Total
    as_temp = get(assSet,ii);
    if ~strcmp(test_assessment_path, as_temp.BlockPath.getBlock(1))
        error('There must be only one Test Assessment block active at the same time. Comment out all the unnecessary blocks.')
    end
end

% Check that the active Test Assessment block is in the model top level
temp_str = split(test_assessment_path,'/');
if length(temp_str) > 2 || ~strcmp(temp_str{1},modelname)
    error('The Test Assessment block must be on the top level of the model.')
end

% Check if the Test Assessment scenario is correct
checkScenario(activeScenarioTA,test_assessment_path);

%% Get the path to the active Test Sequence block

% Get the name of the Test Sequence block
test_sequence_path = '';    % Reset the name of the Test Sequence path
listTS = sltest.testsequence.find;


for ii = 1:length(listTS)
    comment_bool = strcmp(get_param(listTS{ii},'Commented'),'on');
    if ~strcmp(test_assessment_path,listTS{ii}) && ~comment_bool && ~contains(listTS{ii},'sltestlib')
        if isempty(test_sequence_path)
            test_sequence_path = listTS{ii};
        else
            error('There are more than one active Test Sequence and Test Assessment block. Please comment out all the blocks that are not currently in use.')
        end
    end
end

% Check that the active Test Sequence block is in the model top level
temp_str = split(test_sequence_path,'/');
if length(temp_str) > 2 || ~strcmp(temp_str{1},modelname)
    error('The Test Sequence block must be on the top level of the model.')
end

% Check if the Test Sequence scenario is correct
checkScenario(activeScenarioTS,test_sequence_path);

end