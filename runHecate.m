function runHecate(settingName,n_runs)
    %% Declaring model parameters
    beep off
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
    
    % Turn off warning for rmpath in Directory Not Found
    warning off MATLAB:rmpath:DirNotFound
    
    % Add folders to the path
    addpath('TranslationFunctions');
    addpath(genpath('Models'))
    addpath(genpath('staliro'))

    % Set the RNG seed to a random value
    rng('shuffle')

    % Simulate the model and get assessment block/set
    global SettingFile;
    if exist(settingName,'file') == 2
        SettingFile = settingName;
        eval(settingName);  %setting model file
    else
        error('There is no Setting file in the current workpath with the given name.')
    end
    
    % Set the name of the model
    if isa(model,'char')
        modelname = model;
        [test_assessment_path,test_sequence_path] = simConfig(modelname,activeScenarioTA,activeScenarioTS,input_param);
    elseif isa(model,'function_handle')
        modelname = sys;
        [test_assessment_path,test_sequence_path] = simConfig(modelname,activeScenarioTA,activeScenarioTS,input_param,model);
    else
        error('Model type is not supported.')
    end    

    %% Set up translation map

    % Get all steps in the assessment model for the active scenario
    stepTableTA = getAllSteps(activeScenarioTA,test_assessment_path); 
    stepTableTS = getAllSteps(activeScenarioTS,test_sequence_path); 
    
    % Sort the assessment information
    stepTableTA = sortAss(stepTableTA,[],[],activeScenarioTA); % Recursive function
    stepTableTS = sortAss(stepTableTS,[],[],activeScenarioTS); % Recursive function
    
    % Find the formula to compute the fitness value of each predicate
    [stepTableTA, fitTable] = getFit(stepTableTA);
    
    % Get all the transitions information
    transTableTA = getAllTrans(stepTableTA,test_assessment_path);
    transTableTS = getAllTrans(stepTableTS,test_sequence_path);
    
    % Create the state Transition Map
    [~, ~, ~] = buildTransitionMap(test_assessment_path, stepTableTA, transTableTA, fitTable);

    % Check the given input parameters
    input_search = checkTestSequenceParameter(test_sequence_path,input_param,stepTableTS,transTableTS);
    setappdata(0,'input_search',input_search);

    % Create fake S-Taliro variables
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

    tool = 'Hecate';

    % Create name of save file
    if ~isfolder('TestResults')
        mkdir('TestResults')
    end
    
    fileStr = getFileName(tool, settingName)

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
    
    % Initialize struct array
    Results = [];
    History = [];
    Options = [];

    % Run Hecate
    for ii = 1:n_runs
        fprintf('\n\t\t*\t*\t*\n\nRun: %i/%i\n\n',ii,n_runs)
        [results, history, opt] = staliro(modelname, init_cond, input_range_hecate, cp_array_hecate, phi_hecate, preds_hecate, simulationTime, hecate_opt);

        % Save the name of the Hecate parameters
        results.HecateParam = {input_search.Name}';
        history.HecateParam = {input_search.Name}';

        % Add results to the array
        Results = [Results; results];
        History = [History; history];
        Options = [Options; opt];

%         save(fileStr);
	    assignin('base','ResultsHecate',Results)
        assignin('base','HistoryHecate',History)
    end
    
    %% Close the model and save the results

    % Uncomment the Test Assessment block
    set_param(test_assessment_path,'Commented','off');

    % Close Simulink model
    save_system(modelname)
%     close_system(modelname)

%     % Save results
%     save(fileStr);
%     fprintf('\nResults were saved in %s.\n',fileStr);

    beep on
    beep
    pause(0.5)
    beep
    pause(0.5)
    beep

end