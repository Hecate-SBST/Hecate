function runSTaliro(settingName,n_runs)
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
    if exist(settingName,'file') == 2
        eval(settingName);  %setting model file
    else
        error('There is no Setting file in the current workpath with the given name.')
    end

    % Set the name of the model
    if isa(model,'char')
        modelname = model;
        [test_assessment_path,~] = simConfig(modelname,activeScenarioTA,activeScenarioTS,input_param);
    elseif isa(model,'function_handle')
        modelname = sys;
        [test_assessment_path,~] = simConfig(modelname,activeScenarioTA,activeScenarioTS,input_param,model);
    else
        error('Model type is not supported.')
    end

    %% Run S-Taliro

    tool = 'S-Taliro';

    % Create name of save file
    if ~isfolder('TestResults')
        mkdir('TestResults')
    end

    fileStr = datestr(now,'dd_mm_yy_HHMM');
    if contains(settingName,'setting','IgnoreCase',true)
        nameStr = erase(settingName,{'Setting','setting'});
        fileStr = strcat('./TestResults/STaliro_',nameStr,'_',fileStr,'.mat');
    else
        fileStr = strcat('./TestResults/STaliro_',model,'_',fileStr,'.mat');
    end
    
    % Check that the correct version of 'Compute_Robustness' is active
    addpath('TranslationFunctions/Function_STaliro')
    rmpath('TranslationFunctions/Function_Hecate')
    
    % Expand the Atom Predicate formula if the Robustness outport is
    % present
    bool_robOutport = ~isempty(Simulink.findBlocks(modelname,'Name','Outport_Fit_Hecate'));
    if bool_robOutport
        for ii = 1:length(preds)
            preds(ii).A = [preds(ii).A, 0];
        end
    end
    
    % Return the simulation results as separate variables
    outputFormat = get_param(modelname,'ReturnWorkspaceOutputs');
    if ~strcmp(outputFormat,'off')
        set_param(modelname,'ReturnWorkspaceOutputs','off');
    end
    
    % Set all the manual switches to the Inports
    switchOpt = Simulink.FindOptions('SearchDepth',1);
    switchList = Simulink.findBlocksOfType(modelname,'ManualSwitch',switchOpt);
    for ii = 1:length(switchList)
        set_param(switchList(ii),'sw','0')
    end
    
    % Comment out the Test Assessment block to stop assert assessments from
    % interrupting the simulation.
    set_param(test_assessment_path,'Commented','on');
    
    % Initialize struct array
    Results = [];
    History = [];
    Options = [];
    
    % Run S-Taliro
    for ii = 1:n_runs
        fprintf('\n\t\t*\t*\t*\n\nRun: %i/%i\n\n',ii,n_runs)
        [results, history, opt] = staliro(modelname, init_cond, staliro_InputBounds, staliro_cp_array, phi, preds, simulationTime, staliro_opt);
        Results = [Results; results];
        History = [History; history];
        Options = [Options; opt];

        assignin('base','ResultsSTaliro',Results)
        assignin('base','HistorySTaliro',History)
%         save(fileStr);
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