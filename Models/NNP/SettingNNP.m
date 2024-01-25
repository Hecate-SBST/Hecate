% This script is used to define all the variables needed to run the NNP
% benchmark on Hecate

% Call the global variables
global init_cond;
global simulationTime;

% Choose the model
model = 'nn_12B';

% Write requirements in STL
phi = '[]_[0,100] (predz1 /\ predz2)';

preds(1).str = 'predz1';
preds(1).A = [1];
preds(1).b = 1.1;

preds(2).str = 'predz2';
preds(2).A = [-1];
preds(2).b = 0.2;

% Hecate parameters
input_param(1).Name = 'Hecate_RangeX';
input_param(1).LowerBound = -0.5;
input_param(1).UpperBound = 0.5;

input_param(2).Name = 'Hecate_RangeX2';
input_param(2).LowerBound = -0.5;
input_param(2).UpperBound = 0.5;

input_param(3).Name = 'Hecate_RangeY';
input_param(3).LowerBound = -0.5;
input_param(3).UpperBound = 0.5;

input_param(4).Name = 'Hecate_RangeY2';
input_param(4).LowerBound = -0.5;
input_param(4).UpperBound = 0.5;

% Define options
hecateOpt = hecate_options;
hecateOpt.runs = 50;
hecateOpt.optim_params.n_tests = 300;
hecateOpt.sequence_scenario = '';
hecateOpt.assessment_scenario = '';

% Define other parameters
simulationTime = 100;
init_cond = [];

% Define S-Taliro parameters
staliro_InputBounds = [-6 6; -6 6];
staliro_cp_array = [6, 6];
staliro_SimulationTime = simulationTime;
hecateOpt.interpolationtype={'pchip','pchip'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Signal~x~[/]$', '$Signal~y~[/]$'};
output_data.range = [-0.5, 1.5];
output_data.name = {'$NN~Prediction~[/]$'};

% Define variables for the model
evalin('base','load(''new_nn_12B_data'');')