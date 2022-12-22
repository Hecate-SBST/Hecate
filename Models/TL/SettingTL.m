% This script is used to define all the variables needed to run the AT
% benchmark on Hecate

% Call the global variables
global init_cond;
global simulationTime;

% Choose the model
model = 'sltestTrafficLight';

% Traffic light conversion double - LightModeType
%   0 = Green
%   1 = Yellow
%   2 = Red

% Write requirements in STL
phi = '[]_[0,1000] (predLight1 \/ predLight2)';

preds(1).str = 'predLight1';
preds(1).A = [-1 0];
preds(1).b = -1.6;

preds(2).str = 'predLight2';
preds(2).A = [0 -1];
preds(2).b = -1.7;

% Hecate parameters
input_param(1).Name = 'Hecate_Amp1';
input_param(1).LowerBound = -5;
input_param(1).UpperBound = 5;

input_param(2).Name = 'Hecate_Freq1';
input_param(2).LowerBound = 0;
input_param(2).UpperBound = 0.1;

input_param(3).Name = 'Hecate_Amp2';
input_param(3).LowerBound = -5;
input_param(3).UpperBound = 5;

input_param(4).Name = 'Hecate_Freq2';
input_param(4).LowerBound = 0;
input_param(4).UpperBound = 0.1;

input_param(5).Name = 'Hecate_delay';
input_param(5).LowerBound = 0;
input_param(5).UpperBound = 250;


% Name of active scenarios
activeScenarioTA = 'Req_2';
activeScenarioTS = '';

% Define options
staliro_opt = staliro_options;
staliro_opt.optim_params.n_tests = 300;
staliro_opt.SampTime = 0.01;

% Define other parameters
simulationTime = 1000;
init_cond = [];

% Define S-Taliro parameters
staliro_InputBounds = [0 5; 0 5];
staliro_cp_array = [6, 6];
staliro_SimulationTime = simulationTime;
staliro_opt.interpolationtype={'pchip','pchip'};

input_data.range = staliro_InputBounds;
input_data.name = {'$No.~cars~1~[/]$', '$No.~cars~1~[/]$'};
output_data.range = [0, 2; 0, 2];
output_data.name = {'$State~TL~1~[/]$', '$State~TL~2~[/]$'};