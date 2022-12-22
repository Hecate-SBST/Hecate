%% declaring model parameters
clear
warning on verbose

% Turn off warning if verify is falsified
warning off Stateflow:Runtime:TestVerificationFailed

% Turn off warning if the fitness value is Inf
warning off Simulink:Engine:BlockOutputInfNanDetectedError

% Turn off warning for unused symbols in Test Sequence and Test Assessment
warning off Stateflow:reactive:UnusedDataInReactiveTestingTableChart
warning off Stateflow:cdr:UnusedDataOrEvent

% Turn off warning for imposed equality inside verify
warning off Stateflow:cdr:VerifyDangerousComparison

% Add folders to the path
addpath('TranslationFunctions');
addpath(genpath('Models'))
addpath(genpath('staliro'))

%% simulate the model and get assessment block/set

global settingFile;%name of the setting file to simulate
global input_search;

% eval(settingFile); %setting model file
SettingAT;

if isa(model,'char')
    modelname = model;
    [test_assessment_path,test_sequence_path] = simConfig(modelname,activeScenarioTA,activeScenarioTS,input_param);
elseif isa(model,'function_handle')
    modelname = sys;
    [test_assessment_path,test_sequence_path] = simConfig(modelname,activeScenarioTA,activeScenarioTS,input_param,model);
else
    error('Model type is not supported.')
end

%% get all steps in the assessment model for the active scenario
stepTableTA = getAllSteps(activeScenarioTA,test_assessment_path); 
stepTableTS = getAllSteps(activeScenarioTS,test_sequence_path); 

%% Sort the assessment information
stepTableTA = sortAss(stepTableTA,[],[],activeScenarioTA); % Recursive function
stepTableTS = sortAss(stepTableTS,[],[],activeScenarioTS); % Recursive function

%% Find the formula to compute the fitness value of each predicate
[stepTableTA, fitTable] = getFit(stepTableTA);

%% Get all the transitions information
transTableTA = getAllTrans(stepTableTA,test_assessment_path);
transTableTS = getAllTrans(stepTableTS,test_sequence_path);

%% Create the state Transition Map
[stepTableTA, transTableTA, junctionTableTA] = buildTransitionMap(test_assessment_path, stepTableTA, transTableTA, fitTable);

%% Check the given input parameters
input_search = checkTestSequenceParameter(test_sequence_path,input_param,stepTableTS,transTableTS);
setappdata(0,'input_search',input_search);

% Create the parameters for S-Taliro
hecate_opt = staliro_options;
cp_array_hecate = ones(1,length(input_search));
if isempty(input_search)
    input_range_hecate = [];
else
    input_range_hecate = [[input_search.LowerBound]', [input_search.UpperBound]'];
end
hecate_opt.interpolationtype = repmat({'const'},length(input_search),1);
hecate_opt.optim_params.n_tests = staliro_opt.optim_params.n_tests;
phi_hecate = '';
preds_hecate = '';

%% Run Hecate

% Check that the correct version of 'Compute_Robustness' is active
addpath('TranslationFunctions/Function_Hecate')
rmpath('TranslationFunctions/Function_STaliro')

% Set all the manual switches to the Test Sequence
switchOpt = Simulink.FindOptions('SearchDepth',1);
switchList = Simulink.findBlocksOfType(modelname,'ManualSwitch',switchOpt);
for ii = 1:length(switchList)
    set_param(switchList(ii),'sw','1')
end

% Comment out the Test Assessment block to stop assert assessments from
% interrupting the simulation.
set_param(test_assessment_path,'Commented','on');

% Run S-Taliro
[resultsHecate, historyHecate, optHecate] = staliro(modelname, init_cond, input_range_hecate, cp_array_hecate, phi_hecate, preds_hecate, simulationTime, hecate_opt);

% Uncomment the Test Assessment block
set_param(test_assessment_path,'Commented','off');

% ToDo: Change results and history so that it is marked which value corresponds
% to which parameter.

%% Run S-Taliro

% Check that the correct version of 'Compute_Robustness' is active
addpath('TranslationFunctions/Function_STaliro')
rmpath('TranslationFunctions/Function_Hecate')

bool_robOutport = ~isempty(Simulink.findBlocks(modelname,'Name','Outport_Fit_Hecate'));
if bool_robOutport
    for ii = 1:length(preds)
        preds(ii).A = [preds(ii).A, 0];
    end
end

% Return the simulation results as individual variable
outputFormat = get_param(modelname,'ReturnWorkspaceOutputs');
if ~strcmp(outputFormat,'off')
    set_param(modelname,'ReturnWorkspaceOutputs','off');
end

% Set all the manual switches to the Inports
for ii = 1:length(switchList)
    set_param(switchList(ii),'sw','0')
end

% Comment out the Test Assessment block to stop assert assessments from
% interrupting the simulation.
set_param(test_assessment_path,'Commented','on');

% Run S-Taliro
[resultsStaliro, historyStaliro, optStaliro] = staliro(modelname, init_cond, staliro_InputBounds, staliro_cp_array, phi, preds, simulationTime, staliro_opt);

% Uncomment the Test Assessment block
set_param(test_assessment_path,'Commented','off');