% This script is used to define all the variables needed to run the HPS
% benchmark on Hecate

global init_cond;
global simulationTime;

% Choose the model
model = 'HeatPumpScenario';

% Write requirements in STL
phi = '[]_[10,300] (([]_[0, 0.9] predTemp) -> ([]_[1, 1.9]((!predTemp) \/ (predFanPower /\ predPumpPower /\ predPumpDir))))';

preds(1).str = 'predTemp';
preds(1).A = [-1 1 0 0 0];
preds(1).b = -4;

preds(2).str = 'predFanPower';
preds(2).A = [0 0 -1 0 0];
preds(2).b = -0.4;

preds(3).str = 'predPumpPower';
preds(3).A = [0 0 0 -1 0];
preds(3).b = -0.5;

preds(4).str = 'predPumpDir';
preds(4).A = [0 0 0 0 -1];
preds(4).b = -0.6;

% Hecate parameters
input_param(1).Name = 'Hecate_Tset';
input_param(1).LowerBound = 65;
input_param(1).UpperBound = 80;

input_param(2).Name = 'Hecate_Tout';
input_param(2).LowerBound = 85;
input_param(2).UpperBound = 100;

% Define options
hecateOpt = hecate_options;
hecateOpt.runs = 50;
hecateOpt.optim_params.n_tests = 300;
hecateOpt.sequence_scenario = '';
hecateOpt.assessment_scenario = 'Partial';

% Define other parameters
simulationTime = 300;
init_cond = [];

% Define S-Taliro parameters
staliro_InputBounds = [65 80; 40 100];
staliro_cp_array = [1, 1];
staliro_SimulationTime = simulationTime;
hecateOpt.interpolationtype={'const','const'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Reference~Temp~[ºF]$', '$Outside~Temp~[ºF]$'};
output_data.range = [65, 80; 65, 80; 0, 1; 0, 1; -1, 1];
output_data.name = {'$Room~Temp~[ºF]$', '$Reference~Temp~[ºF]$', '$Fan~Power~[T/F]$', '$Pump~Power~[T/F]$', '$Pump~Direction~[/]$'};
