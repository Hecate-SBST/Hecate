% This script is used to define all the variables needed to run the AT2
% benchmark on Hecate

global init_cond;
global simulationTime;

% Choose the model
model = 'AT2';

%X0=[0,0,0];
% Write requirements in STL
phi = '[]_[1,45] ((gearLEQ1 /\ gearGEQ1) -> speedLEQ30) /\ ((gearLEQ2 /\ gearGEQ2) -> speedLEQ50) /\ ((gearLEQ3 /\ gearGEQ3) -> speedLEQ90))';
%phi = '[]_[1,45] ((gearLEQ1 /\ gearGEQ1) -> speedLEQ30))';

preds(1).str = 'gearLEQ0';
preds(1).A = [0 1];
preds(1).b = 0;

preds(2).str = 'gearLEQ1';
preds(2).A = [0 1];
preds(2).b = 1.5;

preds(3).str = 'gearGEQ1';
preds(3).A = [0 -1];
preds(3).b = -0.5;

preds(4).str = 'gearLEQ2';
preds(4).A = [0 1];
preds(4).b = 2.5;

preds(5).str = 'gearGEQ2';
preds(5).A = [0 -1];
preds(5).b = -1.5;

preds(6).str = 'gearLEQ3';
preds(6).A = [0 1];
preds(6).b = 3.5;

preds(7).str = 'gearGEQ3';
preds(7).A = [0 -1];
preds(7).b = -2.5;

preds(8).str = 'speedGEQ0';
preds(8).A = [-1 0];
preds(8).b = 0;

preds(9).str = 'speedLEQ30';
preds(9).A = [1 0];
preds(9).b = 30;

preds(10).str = 'speedLEQ50';
preds(10).A = [1 0];
preds(10).b = 50;

preds(11).str = 'speedLEQ90';
preds(11).A = [1 0];
preds(11).b = 90;

% Hecate params
input_param(1).Name = 'Hecate_Param1';
input_param(1).LowerBound = -20;
input_param(1).UpperBound = +20;

input_param(2).Name = 'Hecate_Param2';
input_param(2).LowerBound = -50;
input_param(2).UpperBound = +50;

input_param(3).Name = 'Hecate_Param3';
input_param(3).LowerBound = -20;
input_param(3).UpperBound = +20;

input_param(4).Name = 'Hecate_Param4';
input_param(4).LowerBound = -50;
input_param(4).UpperBound = +50;

% Name of active scenarios
activeScenarioTA = 'AT2_1';
activeScenarioTS = 'AT2_1';

% Define options
staliro_opt = staliro_options;
staliro_opt.optim_params.n_tests = 300;
staliro_opt.SampTime = 0.01;
staliro_opt.fals_at_zero = 0;

% Define other parameters
simulationTime = 45;
init_cond = [];

% Define S-Taliro parameters
staliro_InputBounds = [0 70; 0 325];
staliro_cp_array = [3, 3];
staliro_SimulationTime = simulationTime;
staliro_opt.interpolationtype={'pchip','pchip'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Throttle~[\%]$', '$Brake~torque~[lb-ft]$'};
output_data.range = [0, 160; 1, 4];
output_data.name = {'$Vehicle~speed~[mph]$', '$Gear~[/]$'};