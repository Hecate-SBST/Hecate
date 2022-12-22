function testTranslation(settingFileName,numRuns)
    % input: the setting file name to test the translation on
    % output: saved file of the assessment data located in /TestResults
    %runs 

    global settingFile
    warning on verbose
    warning off Stateflow:Runtime:TestVerificationFailed
    warning off Stateflow:cdr:UnusedDataOrEvent
    warning off Stateflow:cdr:UnusedDataOrEvent
    warning off Stateflow:cdr:VerifyDangerousComparison
    warning off Stateflow:reactive:UnusedDataInReactiveTestingTableChart
    warning off Simulink:Engine:BlockOutputInfNanDetectedError
    addpath('./TranslationFunctions');
    addpath(genpath('Models')) 
    addpath(genpath('staliro'))
    settingFile=settingFileName; %choose what setting file to use
    eval(settingFile);
    
    % Run simConfig to set up the model
    if isa(model,'char')
        modelname = model;
        [test_assessment_path, ~] = simConfig(modelname,activeScenarioTA,activeScenarioTS,input_param);
    elseif isa(model,'function_handle')
        modelname = sys;
        [test_assessment_path, ~] = simConfig(modelname,activeScenarioTA,activeScenarioTS,input_param,model);
    else
        error('Model type is not supported.')
    end
    
    %% Test the requirements
    
    assessmentData = {};
    staliroData={};

    checkScenario(activeScenarioTA,test_assessment_path);

    % Build the corresponding Transition Map
    stepTableTA = getAllSteps(activeScenarioTA,test_assessment_path); 
    stepTableTA = sortAss(stepTableTA,[],[],activeScenarioTA); % Recursive function
    [stepTableTA, fitTable] = getFit(stepTableTA);
    transTableTA = getAllTrans(stepTableTA,test_assessment_path);
    [~, ~, ~] = buildTransitionMap(test_assessment_path, stepTableTA, transTableTA, fitTable);

    for ii = 1:numRuns

        fprintf('Run %i/%i\n',ii,numRuns)
        tstart = tic;

        %simulink simulate test assessment 
        [robustnessStaliro, input_nodes, simData,fitnessSF] = simModel(model,activeScenarioTA);
        
        telaps = toc(tstart);
        fprintf('Total Simulation time: %f s.\n',telaps)

        %gets staliro pass fail data, sim_node used, simData of assessment
        info = {phi,robustnessStaliro,simData,min(fitnessSF),input_nodes};
        assessmentData(end+1,:)=info;

%             if robustnessStaliro < 0 || min(fitnessSF) < 0
%                 disp('Here')
%             end

%             plot(fitnessSF);
%             title(phi.Properties.RowNames{j});
    end

    assessmentData = cell2table(assessmentData,"VariableNames",["Requirement","Staliro Robustness","Assessment Result","Stateflow Fitness","Sim Node"]);
    assignin('base','Results',assessmentData)

    %% Save results
    assignin('base','Results',assessmentData)

    fileStr=datestr(now,'dd_mm_yy_HHMM');
    if contains(settingFile,'setting','IgnoreCase',true)
        nameStr = erase(settingFile,{'Setting','setting'});
        fileStr = strcat('./TestResults/TranslationCheck_',nameStr,'_',fileStr,'.mat');
    else
        fileStr = strcat('./TestResults/TranslationCheck_',model,'_',fileStr,'.mat');
    end
    
%     try
%         save(fileStr,'assessmentData');
%     catch
%         mkdir ./TestResults
%         save(fileStr,'assessmentData');
%     end
    
    fprintf('Results were saved in %s.\n',fileStr);
end

%% FUNCTIONS

%simulate model
%inputs:
%   T_end -> the end simulation time
%numPhi -> number of phi predicates we're checking
%outputs: 
%   inBound -> input boundary curated to be a single value
%   sim_node -> the values to run the simulation with
%   simData -> the simulation data of pass or fail for all time
%   asName -> name of the assessment step
function [robustnessStaliro,input_nodes,simResult,fitnessSF] = simModel(modelname,activeScenario,modelfcn)

    global settingFile;
    eval(settingFile);

    input_range = staliro_InputBounds;
    T_end = staliro_SimulationTime;
    cp_array = staliro_cp_array;
    interpolation_fcn = staliro_opt.interpolationtype;      % Interpolation function for each input signal
                                                            % Options are:
                                                                % pchip = Cubic interpolation spline
                                                                % interp1 = Linear interpolation

    % Input generation parameters
    dt = 0.01;                                  % Sampling time [s]
    
    % Generate random values for the input values
    [simInpSig, input_nodes,x0]= inputGen(input_range, dt, T_end, cp_array, interpolation_fcn,init_cond);

    % Set all the manual switches to the Inports
    switchOpt = Simulink.FindOptions('SearchDepth',1);
    switchList = Simulink.findBlocksOfType(modelname,'ManualSwitch',switchOpt);
    for ii = 1:length(switchList)
        set_param(switchList(ii),'sw','0')
    end

    % Simulate the model
    if exist('modelfcn','var')
        % If the model is used through a function handle
        SimOut = feval(modelfcn,x0,T_end,simInpSig(:,1),simInpSig(:,2:end));
    else
        % If the model is simulated directly using a Simulink model
        simopt = simget(modelname);
        if ~isempty(x0)
            simopt = simset(simopt, 'InitialState', XPoint);
        end
        SimOut = sim(modelname,[0, T_end],simopt,simInpSig);
    end
    
    % Convert the output datatype into a matrix
    tout = SimOut.(get_param(modelname,'TimeSaveName'));
    yout = SimOut.(get_param(modelname,'OutputSaveName'));

    if ~exist('modelfcn','var')
        outputFormat = get_param(modelname,'SaveFormat');
        switch outputFormat
            case 'Array'
                % Do nothing
            case {'Structure','StructureWithTime'}
                yout = [yout.signals.values];
            case 'Dataset'
                y_temp = zeros(length(tout),numElements(yout));
                for ii = 1:numElements(yout)
                    if length(tout) == length(yout{ii}.Values.Time) && all(tout == yout{ii}.Values.Time)
                        y_temp(:,ii) = yout{ii}.Values.Data;
                    else
                        y_temp(:,ii) = pchip(yout{ii}.Values.Time,yout{ii}.Values.Data,tout);
                    end
                end
                yout = y_temp;
        end
    end

    % Split the fitness value from the normal output
    fitnessSF = yout(:,end);
    yout = yout(:,1:end-1);%-1 because the last output port is the fitness from the stateflow chart created by us
    
    %get the assessment set and number of step objects
    as_set = sltest.getAssessments(modelname);
    numSteps = as_set.getSummary.Total;
    
    simData= []; %stores all the result data 

    for i = 1:numSteps %check all found steps (filter out the wrong scenarios)
        as = get(as_set,i); %get one assessment object
        sp = string(as.BlockPath.SubPath); %the subpath (step name)
    
        if (contains(sp,activeScenario) || isempty(activeScenario))
            as_result = as.Values; %get assessment values pass,fail, not tested
            %-1 is untested   ;   0 is passed   ;   1 is failed
    
            %get the data array
            simData = [simData , as_result.Data];
        end
    end

    if any(strcmp(simData,"Fail"),'all') %any failure means the requirement didn't hold
        simResult="Fail";
    elseif any(strcmp(simData,"Pass"),'all') %no pass or fails means completely inactive
        simResult="Pass";
    else
        simResult="Untested";
    end

    robustnessStaliro = dp_taliro(phi, preds, yout, tout); % robustness tells us if it passed

    if (robustnessStaliro <= 0) ~= (min(fitnessSF) <= 0)
        beep
        disp('Here')
    end

end

function [sim_node, input_nodes, x0]= inputGen(input_range, dt, T_end, cp_array, interpolation_fcn, init_cond)
    % Input generation parameters
    
    if length(cp_array) ~= length(interpolation_fcn) || length(cp_array) ~= size(input_range,1)
        error('Wrong size of input_range, cp_array or interpolation_fcn.')
    end
    
    % --------- Actual input generation ------------------ 
    
    T = (0:dt:T_end)';                 % Time array
    n_input = length(cp_array);     % Number of input signals
    XT = zeros(length(T),n_input);
    input_nodes = [];
    
    for ii = 1:n_input
    
        % Generation of random control points
        t_nodes = linspace(0,T_end,cp_array(ii));
        input_temp = rand(cp_array(ii),1)*(input_range(ii,2)-input_range(ii,1))+input_range(ii,1);%save this variable
        input_nodes = [input_nodes, input_temp'];
    
        % Interpolation of the control points
        switch interpolation_fcn{ii}
            case 'const'
                if length(input_temp) > 1
                    error('If you use the interpolation function const, then the signal must have a single control point. For the piecewise constant interpolation use ''pconst''.')
                end
                signal_temp = input_temp*ones(length(T),1);
            case 'pconst'
                t_nodes = linspace(0,T_end,cp_array(ii)+1);
                signal_temp = zeros(length(T),1);
                for jj = 1:length(t_nodes)-1
                    signal_temp(T >= t_nodes(jj) & T < t_nodes(jj+1)) = input_temp(jj);
                end
                signal_temp(end) = input_temp(end);
            otherwise
                signal_temp = feval(interpolation_fcn{ii},t_nodes,input_temp,T);
        end
        
        XT(:,ii) = signal_temp;
    
        if any(signal_temp > input_range(ii,2)) || any(signal_temp < input_range(ii,1))
            warning('The interpolated values exceeds the input bounds.')
        end
    end
    
    sim_node = [T, XT];

    % ---------- Initial condition generation ----------
    if isempty(init_cond)
        x0 = [];
    else
        x0 = rand(size(init_cond,1),1).*(init_cond(:,2)-init_cond(:,1))+init_cond(:,1);
    end

end
