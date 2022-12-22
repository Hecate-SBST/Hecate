% This script is used to define all the variables needed to run the FS
% benchmark on Hecate

global init_cond;
global simulationTime;

% Choose the model
model = 'FlutterSuppressionSystem';

% Write requirements in STL
phi = '[]_[15,15.01] predDamp';

preds(1).str = 'predDamp';
preds(1).A = [0, -1];
preds(1).b = 0;

% Hecate parameters
input_param(1).Name = 'Hecate_Mach';
input_param(1).LowerBound = 0.1;
input_param(1).UpperBound = 0.2;

input_param(2).Name = 'Hecate_Alt';
input_param(2).LowerBound = 20000;
input_param(2).UpperBound = 30000;

% Name of active scenarios
activeScenarioTA = '';
activeScenarioTS = '';

% Define options
staliro_opt = staliro_options;
staliro_opt.optim_params.n_tests = 300;
staliro_opt.SampTime = 0.01;

% Define other parameters
simulationTime = 15.01;
init_cond = [];

% Define S-Taliro parameters
staliro_InputBounds = [0.1 0.2; 20000 51000];
staliro_cp_array = [1, 1];
staliro_SimulationTime = simulationTime;
staliro_opt.interpolationtype={'const','const'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Mach~number~[/]$', '$Altitude~[ft]$'};
output_data.range = [-1, 1];
output_data.name = {'$Damping~ratio~[/]$'};