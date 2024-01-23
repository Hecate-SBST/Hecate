function [testAssessmentPath,testSequencePath,hecateOpt] = simConfig(modelName,inputParam,hecateOpt,modelFcn)
% Simulate the model once and get the block path and set the active
% scenario, of the Test Sequence and Test Assessment blocks and get all
% input signals to the Test Assessment block.
%
%           [testAssessmentPath,testSequencePath,hecateOpt] = simConfig(modelName,inputParam,hecateOpt,modelFcn)
%
%   E.g.:   [ta_path,ts_path,opt] = simConfig("vdp",input_param,hecateOpt)
%           [ta_path,ts_path,opt] = simConfig("Autotrans_shift",input_param,hecateOpt, @blackbox_AT)
%
% Inputs:
%   modelName: char array containing the name of the model.
%
%   hecateOpt: object of type hecate_options. It contains information on
%   the Test Sequence and Test Assessment scenario under analysis.
%
%   inputParam: struct array containing information on each Hecate input
%   parameter. It has the fields Name, LowerBound and UpperBound.
%
%   modelFcn (Optional): if the model uses a function to run, it is the
%   function handle.
%
% Outputs:
%   testAssessmentPath: char array containing the path to the Test
%   Assessment block.
%
%   testSequencePath: char array containing the path to the Test Sequence
%   block.
%
%   hecateOpt: object of type hecate_options. It contains updated
%   information (if necessary) on the Test Sequence and Test Assessment
%   scenario under analysis.
%
% (C) 2022, Federico Formica, Tony Fan, McMaster University
% (C) 2024, Federico Formica, McMaster University

global initCond;
global simulationTime;

% Check that modelfcn is a function handle (if it is given)
if nargin == 4 && ~isa(modelFcn,"function_handle")
    error("The fourth argument of simConfig must be a function handle.")
end

% Close all the systems open in Simulink exept the one we are investigating
loadedModels = Simulink.allBlockDiagrams("model");
modelNames = get_param(loadedModels,"Name");
modelNames = string(modelNames);
if ~any(strcmp(modelNames,modelName))
    load_system(modelName)
end

for ii = 1:length(modelNames)
    nameTemp = modelNames(ii);
    if ~strcmp(nameTemp,modelName) && bdIsLoaded(nameTemp)
        % TODO: Investigate this issue and remove this temporary fix.
        if ~strcmp(nameTemp,"power_utile")
            save_system(nameTemp)
        end
        close_system(nameTemp)
    
        warning("The model %s was open during the execution of Hecate. For safety, it has been saved and closed.",nameTemp)
    end
end

%% Simulate the model

% Check that the time and output are returned as variables to the workspace
% (only for Simulink models, not for function handles)
if ~exist("modelfcn","var")
    if ~strcmp(get_param(modelName,"SaveTime"),"on")
        set_param(modelName,"SaveTime","on");
        warning("The model is not saving the time array. The model settings have been changed to return the time array as output of the model.") 
    end

    if ~strcmp(get_param(modelName,"SaveOutput"),"on")
        set_param(modelName,"SaveOutput","on");
        warning("The model is not saving the output of the simulation. The model settings have been changed to return the output of the model in the chosen format.") 
    end

    if ~strcmp(get_param(modelName,"ReturnWorkspaceOutputs"),"on")
        set_param(modelName,"ReturnWorkspaceOutputs","on");
        warning("The model is not returning the simulation results as a single variable. The model settings have been changed accordingly.") 
    end

    if ~strcmp(get_param(modelName,"LoggingToFile"),"off")
        set_param(modelName,"LoggingToFile","off");
        warning("The model is logging the simulation results to an external file, instead of Matlab. This model setting has been deactivated.") 
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

%% Get the path to the active Test Assessment block

% Get the assessment from the Test Assessment block
assSet = sltest.getAssessments(modelName); % Get the entire Assessment set
assSetSummary = getSummary(assSet);
if assSetSummary.Total < 1
    error("The Test Assessment block does not contain any assessment.")
end

% Get the blockpath to the test assessment block
as = get(assSet,1); % Get first assessment object from the set
testAssessmentPath = string(as.BlockPath.getBlock(1)); % Path to Test Assessment block that the assessment object belongs to

% Check that all the active assessments come from the same Test Assessment
% block
for ii = 1:assSetSummary.Total
    asTemp = get(assSet,ii);
    if ~strcmp(testAssessmentPath, asTemp.BlockPath.getBlock(1))
        error("There must be only one Test Assessment block active at the same time. Comment out all the unnecessary blocks.")
    end
end

% Check that the active Test Assessment block is in the model top level
strTemp = split(testAssessmentPath,"/");
if length(strTemp) > 2 || ~strcmp(strTemp(1),modelName)
    error("The Test Assessment block must be on the top level of the model.")
end

% Check if the Test Assessment scenario is correct
hecateOpt = checkScenario(hecateOpt,testAssessmentPath,false);

%% Get the path to the active Test Sequence block

% Get the name of the Test Sequence block
testSequencePath = "";    % Reset the name of the Test Sequence path
listTS = sltest.testsequence.find;


for ii = 1:length(listTS)
    commentBool = strcmp(get_param(listTS{ii},"Commented"),"on");
    if ~strcmp(testAssessmentPath,listTS{ii}) && ~commentBool && ~contains(listTS{ii},"sltestlib")
        if strcmp(testSequencePath,"")
            testSequencePath = listTS{ii};
        else
            error("There are more than one active Test Sequence and Test Assessment block. Please comment out all the blocks that are not currently in use.")
        end
    end
end

% Check that the active Test Sequence block is in the model top level
strTemp = split(testSequencePath,"/");
if length(strTemp) > 2 || ~strcmp(strTemp(1),modelName)
    error("The Test Sequence block must be on the top level of the model.")
end

% Check if the Test Sequence scenario is correct
hecateOpt = checkScenario(hecateOpt,testSequencePath,true);

end