function [Results,History,Options] = hecate(modelName,inputParam,simulationTime,hecateOpt)
% Automatically generates test cases for a Simulink model using a
% Parametrized Test Sequence block.
%
%           [Results,History,Options] = hecate(modelName,inputParam,simulationTime,hecateOpt)
%
%   E.g.:   [Results,History,Options] = hecate("vdp",inputParam,50,hecateOpt)
%
% Inputs:
%   modelName: char array or string containing the name of the Simulink
%   model under analysis.
%
%   inputParam: struct array containing information on the Hecate
%   parameters used in the Test Sequence. All the Hecate parameters used in
%   the Test Sequence must be specified, even if they are not used by the
%   current active scenario. For each parameter, this variable must contain
%   its name and the upper and lower bound (all Hecate parameters are
%   assumed to be real values by the search algorithm).
%       inputParam(1).Name = 'Hecate_param';
%       inputParam(1).LowerBound = 0;
%       inputParam(1).UpperBound = 10;
%
%   simulationTime: Lenght in seconds of the simulation time. This value
%   overwrites what is specified in the Simulink model.
%
%   hecateOpt: object of type hecate_options. It contains information on
%   the Test Sequence and Test Assessment scenarios and how to execute the
%   search algorithm.
%
% Output:
%   Results: struct array containing the main results of the Hecate
%   algorithm, such as the number of iterations required to find the
%   failure-revealing test case and the values of the Hecate parameters
%   associated with the failure-revealing test case or the test case with
%   the lowest robustness. Each element of the array represents a different
%   run.
%
%   History: struct array containing information on all the test cases
%   tried by the search algorithm and their robustness value. Each element
%   of the array represents a different
%   run.
%
%   Options: object of type hecate_options. It is a copy of hecateOpt, but
%   some options may have been updated by the algorithm automatic checks.
%
% The details of this algorithm have been presented in the following paper:
% F. Formica, T. Fan, A. Rajhans, V. Pantelic, M. Lawford and C. Menghi,
% "Simulation-based Testing of Simulink Models with Test Sequence and Test
% Assessment Blocks," in IEEE Transactions on Software Engineering, doi:
% 10.1109/TSE.2023.3343753.
%
% (C) 2022, Federico Formica, Tony Fan, McMaster University
% (C) 2024, Federico Formica, McMaster University

%% Create Fitness Converter subsystem

% Find Test Sequence and Test Assessment path
if isa(modelName,"char") || isa(modelName,"string")
    [assessmentPath,sequencePath] = simConfig(modelName,inputParam,hecateOpt);
else
    error("Model type is not supported.")
end

% Get content of Test Sequence and check parameters
stepTableTS = getAllSteps(hecateOpt.sequence_scenario,sequencePath);
stepTableTS = sortAss(stepTableTS,[],[],hecateOpt.sequence_scenario);
transTableTS = getAllTrans(stepTableTS,sequencePath);
    % TODO: We are overwriting inputParam, considering only the relevant
    % Hecate parameters and removing the negligible ones. Check if we are
    % losing any useful information.
inputParam = checkTestSequenceParameter(sequencePath,inputParam,stepTableTS,transTableTS);
if isempty(inputParam)
    error("The selected Test Sequence scenario '%s' does not contain any Hecate parameter.\nTo use Hecate," + ...
        " choose a scenario that contains at least a parameter starting with 'Hecate_'.",hecateOpt.sequence_scenario)
end

% Export Hecate parameters information to other functions.
global inputSearch;
inputSearch = inputParam;
%setappdata(0,"inputSearch",inputParam);

% Get content of Test Assessment and create fitness functions
stepTableTA = getAllSteps(hecateOpt.assessment_scenario,assessmentPath);
stepTableTA = sortAss(stepTableTA,[],[],hecateOpt.assessment_scenario);
[stepTableTA, fitTable] = getFit(stepTableTA);
transTableTA = getAllTrans(stepTableTA,assessmentPath);
buildTransitionMap(assessmentPath, stepTableTA, transTableTA, fitTable);

%% Run test case generation algorithm

% Check if the upper bound of each Hecate parameter is greater or equal
% than its lower bound.
if ~all([inputParam.LowerBound] <= [inputParam.UpperBound])
    idxTemp = find([inputParam.LowerBound] > [inputParam.UpperBound]);
    paramName = {inputParam.Name};
    ErrMsg = sprintf("The following parameters have a Lower Bound that is strictly greater\n" + ...
        "than the Upper Bound. Fix them before running Hecate again.\n");
    for ii = 1:length(idxTemp)
        ErrMsg = ErrMsg + sprintf("\t* %s\n",paramName{idxTemp(ii)});
    end
    error(ErrMsg);
end

% Create fake variables for S-Taliro
if isa(modelName,"string")
    modelName = char(modelName);
end
controlPointsHecate = ones(1,length(inputParam));
inputRangeHecate = [[inputParam.LowerBound]', [inputParam.UpperBound]'];
hecateOpt.interpolationtype = repmat({'const'},length(inputParam),1);
initCondHecate = [];
phiHecate = '';
predsHecate = '';

% Initialize struct array for Results
Results = [];
History = [];
Options = [];

% Save number of runs as a separate parameter
nRuns = hecateOpt.runs;
hecateOpt.runs = 1;

% Deactivate intermediate saving with S-Taliro
interSave = hecateOpt.save_intermediate_results;
if interSave
    hecateOpt.save_intermediate_results = 0;
end

% Check intermediate save name
fileStr = hecateOpt.save_intermediate_results_varname;
if interSave && (isempty(fileStr) || fileStr == "" || strcmp(fileStr,"default"))
    fileStr = string(datetime("now","Format","yyyy-MMM-dd-HH:mm:ss"));
    fileStr = "Hecate_" + fileStr + "_" + string(modelName) + ".mat";
end

% Comment out Test Assessment block to avoid interruptions due to assert
% statements.
set_param(assessmentPath,"Commented","on");

% Use try-catch to uncomment block in case of errors
try
    % Loop over runs
    for ii = 1:nRuns
        fprintf("\n\t\t*\t*\t*\n\nRun: %i/%i\n\n",ii,nRuns)

        % Run S-Taliro
        [results, history, opt] = staliro(modelName, initCondHecate, inputRangeHecate, controlPointsHecate, phiHecate, predsHecate, simulationTime, hecateOpt);

        % Save the name of the Hecate parameters in the correct order
        results.HecateParam = {inputParam.Name}';
        history.HecateParam = {inputParam.Name}';

        % Change number of runs in the option variable
        opt.runs = nRuns;

        % Change intermediate saving option if necessary
        opt.save_intermediate_results = interSave;

        % Add results variable to the array
        Results = [Results; results];
        History = [History; history];
        Options = [Options; opt];

        % Save intermediate results
        if interSave
            save(fileStr,"Results","History","Options","nRuns")
        end

    end
catch except
    set_param(assessmentPath,"Commented","off");
    rethrow(except);
end

% Uncomment the Test Assessment block
set_param(assessmentPath,"Commented","off");

%% Display Hecate results

if hecateOpt.disp_results

    resultTemp = [Results.run];
    resultTable = table('Size',[0 2],'VariableTypes',{'string','string'},...
        'VariableNames',{'Parameter','Value'});
        % Note: table must use char instead of string to properly recognize
        % property names.

    % Success Rate
    success = boolean([resultTemp.falsified]);
    SR = sum(success)/length(success);
    Performance.SuccessRate = SR;
    resultTable = [resultTable; {"Success Rate", sprintf("%.1f %%",SR*100)}];

    % Number of iterations
    iter = [resultTemp.nTests];
    iter = iter(success);
    Performance.AvgIter = mean(iter);
    Performance.MedIter = median(iter);
    if isempty(iter)
        resultTable = [resultTable; {"Average Iterations", "-"}];
        resultTable = [resultTable; {"Median Iterations", "-"}];
    else
        resultTable = [resultTable; {"Average Iterations", sprintf("%.1f",mean(iter))}];
        resultTable = [resultTable; {"Median Iterations", sprintf("%.1f",median(iter))}];
    end

    % Robustness
    rob = [resultTemp.bestCost];
    rob = rob(~success);
    Performance.AvgRob = mean(rob);
    Performance.MedRob = median(rob);
    if isempty(rob)
        resultTable = [resultTable; {"Average Robustness", "-"}];
        resultTable = [resultTable; {"Median Robustness", "-"}];
    else
        resultTable = [resultTable; {"Average Robustness", sprintf("%.3e",mean(rob))}];
        resultTable = [resultTable; {"Median Robustness", sprintf("%.3e",median(rob))}];
    end

    % Time
    if hecateOpt.TimeStatsCollect
        time = [resultTemp.time];
        simTime = [time.simTime];
        totTime = [time.totTime];
        Performance.SimtoTotTime = mean(simTime./totTime);
        resultTable = [resultTable; {"Ratio Simulation to Total time", ...
            sprintf("%.1f %%",mean(simTime./totTime)*100)}];
        totTime = totTime(success);
        Performance.AvgTime = mean(totTime);
        Performance.MedTime = median(totTime);
        if isempty(totTime)
            resultTable = [resultTable; {"Average Time", "-"}];
            resultTable = [resultTable; {"Median Time", "-"}];
        else
            resultTable = [resultTable; {"Average Time", sprintf("%.3e s",mean(totTime))}];
            resultTable = [resultTable; {"Median Time", sprintf("%.3e s",median(totTime))}];
        end
    end

    % Display performance indicators
    fprintf("\n\t*\t*\t*\n\n")
    fprintf("Performance parameters of the Hecate runs:\n\n")
    performanceTemp = repmat({Performance},nRuns,1);
    [Results.Performance] = performanceTemp{:};
    disp(resultTable);
end

end