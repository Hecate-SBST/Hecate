%% Tutorial on the use of Hecate with Test Assessment on an Automotive model.
% The following is a tutorial on how to use Hecate to generate
% failure-revealing test case for a model of an automotive automatic
% transmission reading the specification from a Test Assessment block.
% Make sure you have installed Hecate as described in the README.md and
% that the Hecate src folder has been added to the active path.

% Add to the path the relevant folders. This does nothing if the folders
% have already been added to the path. Change the name of the folder
% containing S-Taliro based on the name you used.
addpath(genpath("src"))
addpath(genpath("staliro"))

%% Remove unnecessary warnings (optional)
% Running Hecate can trigger some warning messages. This is normal and
% expected behaviour, so this section deactivates some specific warnings.

% Warning for unused symbols in the Test Sequence/Assessment.
warning off Stateflow:reactive:UnusedDataInReactiveTestingTableChart

% Warning for unused symbols in the Fitness Converter Stateflow Chart.
warning off Stateflow:cdr:UnusedDataOrEvent

% Warning for requirement violation.
warning off Stateflow:Runtime:TestVerificationFailed

%% Define settings for Hecate

% Set the RNG seed to a random value. This is important to have different
% results if Hecate is run multiple times just after opening Matlab
% (important if you run the experiments on a server).
rng("shuffle")

% Define the model name (the file extension can be omitted)
modelName = 'AutomaticTransmission';

% Define Hecate parameter properties in a struct array variable.
% Each Hecate parameter must be defined in this array, even if they are not
% used by the active Test Sequence scenario. The order of the parameters is
% not important.
% For each parameter, the following properties must be defined:
% - Name, as written in the Test Sequence
% - Lower bound
% - Upper bound
inputParam(1).Name = 'Hecate_throttle';
inputParam(1).LowerBound = 50;
inputParam(1).UpperBound = 65;

inputParam(2).Name = 'Hecate_brakeAmp';
inputParam(2).LowerBound = 0;
inputParam(2).UpperBound = 40;

inputParam(3).Name = 'Hecate_brakePeriod';
inputParam(3).LowerBound = 2;
inputParam(3).UpperBound = 20;

inputParam(4).Name = 'Hecate_throttleDuration';
inputParam(4).LowerBound = 5;
inputParam(4).UpperBound = 30;

inputParam(5).Name = 'Hecate_throttleMax';
inputParam(5).LowerBound = 70;
inputParam(5).UpperBound = 100;

inputParam(6).Name = 'Hecate_throttleSlope';
inputParam(6).LowerBound = 0.04;
inputParam(6).UpperBound = 0.2;

% Define Simulation Time for the model (in seconds).
% This value overwrites the one defined inside the model.
simulationTime = 50;

% Create the Hecate options object.
% Check the hecate_options.m and staliro_options.m files for a description
% of each property and what is the default value.
hecateOpt = hecate_options();

% Let's set the search algoritm to Uniform Random (UR_Taliro), instead of
% Simulated Annealing (SA_Taliro), which is the default option.
hecateOpt.optimization_solver = 'UR_Taliro';

% The maximum number of iterations per run is set to 50.
% Note: Always define this parameter after choosing the search algorithm.
hecateOpt.optim_params.n_tests = 50;

% The experiment will be repeated for 5 runs to make some statistical
% considerations.
hecateOpt.runs = 5;

% This option specifies whether the tool should read a Test Assessment or a
% Requirements Table block.
hecateOpt.spec_source = "test_assessment";

% This option defines which Test Sequence scenario must be used for test
% case generation.
% The model under consideration has three:
% * Manual (not compatible with Hecate, it does not contain any Hecate
% parameters).
% * ThreeSteps: 1 Hecate parameter.
% * Trapezoidal: 6 Hecate parameters.
% hecateOpt.sequence_scenario = 'ThreeSteps';
hecateOpt.sequence_scenario = 'Trapezoidal';

% This option defines which Test Assessment scenario must be used for
% requirement specification.
% The model under consideration has two:
% * SpeedLimit: 1 step.
% * TestGear: 5 steps.
% hecateOpt.assessment_scenario = 'SpeedLimit';
hecateOpt.assessment_scenario = 'TestGear';

% This option allows to save the results after each run to minimise data
% loss. In this case, the model is very fast, so we choose not to save the
% intermediate results.
hecateOpt.save_intermediate_results = 0;

% This option allows to save some time information on computational time
% and simulation time in the Results variable.
hecateOpt.TimeStatsCollect = 1;

% This option allows to compute some performance parameters over all the
% runs considered, save them in the Results variable and display them at
% the end.
hecateOpt.disp_results = 1;

%% Run Hecate

[Results,History,Options] = hecate(modelName,inputParam,simulationTime,hecateOpt);

%% Save results

% Create file name
fileStr = string(datetime("now","Format","yyyy-MMM-dd-HH:mm:ss"));
fileStr = "./HecateTutorialTA_" + fileStr + ".mat";

% Save results
save(fileStr);
fprintf("\nResults were saved in %s.\n",fileStr);