% This script is used to define all the variables needed to run the SC
% benchmark on Hecate

% Call the global variables
global init_cond;
global simulationTime;

% Choose the model
model = 'stc';

% Write requirements
phi = '[]_[30,35] (p1/\p2)';

preds(1).str = 'p1';
preds(1).A =  [0 0 0 1];
preds(1).b =  87.5;

preds(2).str = 'p2';
preds(2).A =  [0 0 0 -1];
preds(2).b =  -87;

% Hecate parameters
input_param(1).Name = 'Hecate_flow1';
input_param(1).LowerBound = 3.985;
input_param(1).UpperBound = 4.015;

input_param(2).Name = 'Hecate_delay';
input_param(2).LowerBound = 5;
input_param(2).UpperBound = 25;

input_param(3).Name = 'Hecate_Amp';
input_param(3).LowerBound = 0;
input_param(3).UpperBound = 0.015;

input_param(4).Name = 'Hecate_Freq';
input_param(4).LowerBound = 0.2;
input_param(4).UpperBound = 0.3;

% Name of active scenarios
activeScenarioTA = '';
activeScenarioTS = '';

% Define options
staliro_opt = staliro_options;
staliro_opt.optim_params.n_tests = 300;
staliro_opt.SampTime=0.01;

% Define other parameters
simulationTime = 35;
init_cond = [];

% Define S-Taliro parameters
staliro_InputBounds = [3.985 ,4.015];
staliro_cp_array = 20;
staliro_SimulationTime = simulationTime;
staliro_opt.interpolationtype={'pchip'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Steam~flow~rate$'};
output_data.range = [85, 95; 8500, 10000; 100, 130; 80, 90];
output_data.name = {'$Temperature$', {'$Cooling~water$','$flow~rate$'}, '$Heat~dissipated$', '$Steam~pressure$'};
