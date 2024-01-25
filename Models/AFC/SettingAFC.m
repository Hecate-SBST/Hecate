% This script is used to define all the variables needed to run the AFC
% benchmark on Hecate

% Call the global variables
global init_cond;
global simulationTime;

% Choose the model
model = 'AbstractFuelControl_v2';

% Requirements parameters
beta = 0.008;
gamma = 0.007;

% Write requirements
afc29 = '[]_[11,50](ugr /\ ugl)';
afc33 = '[]_[11,50](ugr /\ ugl)';

preds(1).str = 'ugr';   % u <= gamma
preds(1).A = 1;
preds(1).b = gamma;

preds(2).str = 'ugl';   % u >= -gamma
preds(2).A = -1;
preds(2).b = gamma;

% Hecate params
input_param(1).Name = 'Hecate_RPM';
input_param(1).LowerBound = 1050;
input_param(1).UpperBound = 1100;

input_param(2).Name = 'Hecate_delay1';
input_param(2).LowerBound = -0.5;
input_param(2).UpperBound = 0.5;

input_param(3).Name = 'Hecate_throttle1';
input_param(3).LowerBound = 45;
input_param(3).UpperBound = 61.2;

input_param(4).Name = 'Hecate_throttle2';
input_param(4).LowerBound = 1;
input_param(4).UpperBound = 10;

input_param(5).Name = 'Hecate_throttle3';
input_param(5).LowerBound = 45;
input_param(5).UpperBound = 61.2;

% Name of chosen requirement
phi = afc29;

% Define options
hecateOpt = hecate_options;
hecateOpt.runs = 50;
hecateOpt.optim_params.n_tests = 300;
hecateOpt.sequence_scenario = 'AFC29';
hecateOpt.assessment_scenario = 'AFC29';

% Define other parameters
simulationTime = 50;
init_cond = [];

% Define S-Taliro parameters
staliro_InputBounds = [1 61.2; 900  1100];
% For AFC29: staliro_InputBounds = [0 61.2; 900  1100];
% For AFC33: staliro_InputBounds = [61.2 81.2; 900  1100];
staliro_cp_array = [10, 1];
staliro_SimulationTime = simulationTime;
hecateOpt.interpolationtype={'pconst','const'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Engine~speed~[rpm]$', '$Throttle~angle~[deg]$'};
output_data.range = [-0.04, 0.04; 0, 1; 0, 61.2];
output_data.name = {'$Verification~[/]$', '$Mode~[/]$', '$Throttle~angle~[deg]$'};

% Define variables for the model
assignin('base','simTime',simulationTime)
assignin('base','en_speed',1000)
assignin('base','measureTime',1)
assignin('base','spec_num',1)
assignin('base','fuel_inj_tol',1)
assignin('base','MAF_sensor_tol',1)
assignin('base','AF_sensor_tol',1)
assignin('base','sim_time',simulationTime)
assignin('base','fault_time',60)
