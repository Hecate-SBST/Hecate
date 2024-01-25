% This script is used to define all the variables needed to run the AT
% benchmark on Hecate

% Call the global variables
global init_cond;
global simulationTime;

% Choose the model
model = 'Autotrans_shift';

% Write requirements in STL
at1 = '[]_[0,20] speed120';
at2 = '[]_[0,10] rpm4750';

preds(1).str = 'speed120';
preds(1).A = [1 0 0];
preds(1).b = 120;

preds(2).str = 'rpm4750';
preds(2).A = [0 1 0];
preds(2).b = 4750;

% Hecate parameters
input_param(1).Name = 'Hecate_param1';
input_param(1).LowerBound = 70;
input_param(1).UpperBound = 110;

input_param(2).Name = 'Hecate_param2';
input_param(2).LowerBound = 0;
input_param(2).UpperBound = 80;

input_param(3).Name = 'Hecate_param3';
input_param(3).LowerBound = 70;
input_param(3).UpperBound = 110;

input_param(4).Name = 'Hecate_param4';
input_param(4).LowerBound = 0;
input_param(4).UpperBound = 80;

% Name of chosen requirement
phi = at1;

% Define options
hecateOpt = hecate_options;
hecateOpt.runs = 50;
hecateOpt.optim_params.n_tests = 300;
hecateOpt.sequence_scenario = '';
hecateOpt.assessment_scenario = 'AT1';

% Define other parameters
simulationTime = 20;
init_cond = [];

% Define S-Taliro parameters
%staliro_InputBounds = [0 100; 0 325];
staliro_InputBounds = [0 110; 0 325];
staliro_cp_array = [7, 3];
staliro_SimulationTime = simulationTime;
hecateOpt.interpolationtype={'pchip','pchip'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Throttle~[\%]$', '$Brake~torque~[lb-ft]$'};
output_data.range = [0, 160; 0, 5000; 1, 4];
output_data.name = {'$Vehicle~speed~[mph]$', '$Engine~speed~[rpm]$', '$Gear~[/]$'};