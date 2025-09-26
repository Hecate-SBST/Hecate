function [reqTablePath,testSequencePath,hecateOpt] = simConfigRT(modelName,inputParam,hecateOpt,modelfcn)
% Get the block path and set the active scenario of the Test Sequence and
% Requirement Table blocks and get all input signals to the Requirement
% Table block.
%
%           [req_table_path,test_sequence_path] = simConfig(modelname,activeScenarioTS,modelfcn)
%
%   E.g.:   [rq_path,ts_path] = simConfig('vdp','Scenario_1')
%           [rq_path,ts_path] = simConfig('Autotrans_shift','AT_1', @blackbox_AT)
%
% Inputs:
%   modelname: char array containing the name of the model.
%
%   activeScenarioTS: char array containing the name of the active Scenario
%   in the Test Sequence block. If the Test Sequence block does not use
%   Scenarios, then this variable must be an empty char array: ''.
%   
%   input_param: carry  hecate input parameters containing param name, lower
%   bound and upper bound 
%
%   modelfcn (Optional): if the model uses a function to run, it is the
%   function handle.
%
% Outputs:
%   req_table_path: char array containing the path to the Requirement Table
%   block.
%
%   test_sequence_path: char array containing the path to the Test Sequence
%   block.

global initCond;
global simulationTime;

% Check that modelfcn is a function handle (if it is given)
if nargin == 4 && ~isa(modelfcn,'function_handle')
    error('The fourth argument of simConfig must be a function handle.')
end

% Close all the systems open in Simulink exept the one we are investigating
loadedModels = Simulink.allBlockDiagrams("model");
modelNames = string(get_param(loadedModels,"Name"));
if ~any(strcmp(modelNames,modelName))
    load_system(modelName)
end

for ii = 1:length(modelNames)
    if ~strcmp(modelNames(ii),modelName) && bdIsLoaded(modelNames(ii))
        if ~strcmp(modelNames(ii),'power_utile')
            save_system(modelNames(ii))
        end
        close_system(modelNames(ii))
    
        warning('The model %s was open during the execution of Hecate. For safety, it has been saved and closed.',modelNames(ii))
    end
end

%% Set the model options and run the model once.

% Check that the time and output are returned as variables to the workspace
% (only for Simulink models, not for function handles)
if ~exist('modelfcn','var')
    timeSave = get_param(modelName,'SaveTime');
    if ~strcmp(timeSave,'on')
        set_param(modelName,'SaveTime','on');
        warning('The model is not saving the time array. The model settings have been changed to return the time array as output of the model.') 
    end

    outputSave = get_param(modelName,'SaveOutput');
    if ~strcmp(outputSave,'on')
        set_param(modelName,'SaveOutput','on');
        warning('The model is not saving the output of the simulation. The model settings have been changed to return the output of the model in the chosen format.') 
    end

    outputFormat = get_param(modelName,'ReturnWorkspaceOutputs');
    if ~strcmp(outputFormat,'on')
        set_param(modelName,'ReturnWorkspaceOutputs','on');
        warning('The model is not returning the simulation results as a single variable. The model settings have been changed accordingly.') 
    end
end

% Generate a random value for Hecate parameters
T_end = simulationTime;
paramTemp = zeros(length(inputParam),1);
for ii = 1:length(inputParam)
    paramTemp(ii) = rand(1)*(inputParam(ii).UpperBound-inputParam(ii).LowerBound)+inputParam(ii).LowerBound;
    assignin("base",inputParam(ii).Name,paramTemp(ii));
end

if ~isempty(initCond)
    x0 = rand(size(initCond,1),1).*(diff(initCond,1,2))+initCond(:,1);
else
    x0 = [];
end

% Simulate the model with a random input and random initial conditions
if exist("modelfcn","var")
    % If the model uses a matlab function to run.
    feval(modelFcn,x0,T_end,[],[]);
else
    % If the model is simulated directly using a Simulink model.
    simopt = simget(modelName);
    if ~isempty(x0)
        simopt = simset(simopt, "InitialState", XPoint);
    end
    try
        sim(modelName,[0, T_end],simopt);
    catch Err
        % If the simulation was interrupted by an assert statement, the
        % system will ignore the error message.
        if ~isa(Err,"MSLException") || ~strcmp(Err.identifier,"Stateflow:Runtime")
            throw(Err)
        end
    end
end

%% Get the path to the active Requirement Table block

% Find all Requirement Tables in model
tables_Temp = slreq.modeling.find(modelName);
if isempty(tables_Temp)
    error('The model %s does not contain any Requirement Tables.', modelName)
end
tablesPath_Temp = {tables_Temp.Path};

% Filter out Requirement Tables not in the root level
reqTablePath = {};
for ii = 1: length(tablesPath_Temp)
    strTemp = split(tablesPath_Temp{ii},'/');
    if length(strTemp) <= 2
        reqTablePath = [reqTablePath; tablesPath_Temp(ii)];
    end
end

% Checks on Requirement Tables.
if isscalar(reqTablePath)
    reqTablePath = string(reqTablePath);
elseif length(reqTablePath) > 1
    warning('There are multiple Requirement Tables at the root level of the model %s.\n Only the one made first will be taken into consideration.', modelName)
    reqTablePath = string(reqTablePath{1});
else
    error('The model %s does not contain any Requirement Tables at the root level.', modelName)
end

%% Get the path to the active Test Sequence block

% Get the name of all Test Sequence and Test Assessment blocks
testSequencePath = '';    % Reset the name of the Test Sequence path
listTS = sltest.testsequence.find;

% Get name of Test Assessment blocks pnly
assSet = sltest.getAssessments(modelName); % Get the entire Assessment set
assSetSummary = getSummary(assSet);
testAssessmentList = [];
for ii = 1:assSetSummary.Total
    asTemp = get(assSet,ii); % Get assessment object from the set
    if ~any(strcmp(asTemp.BlockPath.getBlock(1),{tables_Temp.Path})) && ...
            ~any(strcmp(asTemp.BlockPath.getBlock(1),testAssessmentList))
        testAssessmentList = [testAssessmentList, string(asTemp.BlockPath.getBlock(1))]; % Path to Test Assessment block that the assessment object belongs to
    end
end

% Ignore blocks that are commented out or are Test Assessment blocks.
for ii = 1:length(listTS)
    comment_bool = strcmp(get_param(listTS{ii},'Commented'),'on') || ...
        any(strcmp(listTS{ii},testAssessmentList));
    if ~comment_bool && ~contains(listTS{ii},'sltestlib')
        if isempty(testSequencePath)
            testSequencePath = listTS{ii};
        else
            error('There is more than one active Test Sequence block. Please comment out all the blocks that are not currently in use.')
        end
    end
end

% Check that the active Test Sequence block is in the model top level
temp_str = split(testSequencePath,'/');
if length(temp_str) > 2 || ~strcmp(temp_str{1},modelName)
    error('The Test Sequence block must be on the top level of the model.')
end

% Check if the Test Sequence scenario is correct
hecateOpt = checkScenario(hecateOpt,testSequencePath,true);

%% Assign a random value to all hecate params
for ii = 1:length(inputParam)
    paramTemp = inputParam(ii).LowerBound + rand(1)*(inputParam(ii).UpperBound - inputParam(ii).LowerBound);
    assignin("base",inputParam(ii).Name,paramTemp);
end 

end