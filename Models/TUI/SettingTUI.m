% This script is used to define all the variables needed to run the AT
% benchmark on Hecate

% Call the global variables
global init_cond;
global simulationTime;

% Choose the model
model = 'integrator_12B';

% Write requirements in STL
TL = 10;        % Top Limit
BL = -10;        % Bottom Limit (choose value that is not immediately falsified)
%phi = '[]_[0,20] (predTL /\ predBL)';
phi = '[]_[0,20] (predTL)';

preds(1).str = 'predTL';
preds(1).A = [1];
preds(1).b = 10;

preds(2).str = 'predBL';
preds(2).A = [-1];
preds(2).b = -10;

% Hecate parameters
input_param(1).Name = 'Hecate_Amp';
input_param(1).LowerBound = -0.5;
input_param(1).UpperBound = 0.5;

input_param(2).Name = 'Hecate_Freq';
input_param(2).LowerBound = -0.5;
input_param(2).UpperBound = 0.5;

input_param(3).Name = 'Hecate_Slope';
input_param(3).LowerBound = -2;
input_param(3).UpperBound = 2;

input_param(4).Name = 'Hecate_ResetThres';
input_param(4).LowerBound = 0.5;
input_param(4).UpperBound = 1;

% Name of active scenarios
activeScenarioTA = '';
activeScenarioTS = 'TUI2';

% Define options
staliro_opt = staliro_options;
staliro_opt.optim_params.n_tests = 300;
staliro_opt.SampTime = 0.01;

% Define other parameters
simulationTime = 20;
init_cond = [];

% Define S-Taliro parameters
staliro_InputBounds = [-1, 1; 0 0.6];
staliro_cp_array = [3, 4];
staliro_SimulationTime = simulationTime;
staliro_opt.interpolationtype={'pchip','pconst'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Signal~[/]$', '$Reset~[Y/N]$'};
output_data.range = [BL, TL];
output_data.name = {'$Integral~value~[/]$'};

% Define variables for the model
assignin('base','TL',TL)
assignin('base','BL',BL)
