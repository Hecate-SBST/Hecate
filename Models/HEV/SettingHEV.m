% This script is used to define all the variables needed to run the AT
% benchmark on Hecate

global init_cond;
global simulationTime;

startup_HEV_Model;
Setup_HEV_Model_Configurations;
Configure_HEV_Simulation;
HEV_Model_PARAM;
Drive_Cycle_Num=3;

load('UrbanCycle1.mat');
load('UrbanCycle2.mat');
load('UrbanCycle3.mat');
load('UrbanCycle4.mat');

% Choose the model
model = 'HEV_SeriesParallel';

% Write requirements in STL
hev1 = '[]_[101,110] speed120';

req = {'HEV1'};
str = {hev1;};
phi = table(str,'RowNames',req);

preds(1).str = 'speed120';
preds(1).A = [1];
preds(1).b = 1;

% Hecate params
input_param(1).Name = 'Hecate_param1';
input_param(1).LowerBound = 0;
input_param(1).UpperBound = 4;

input_param(2).Name = 'Hecate_param2';
input_param(2).LowerBound = 0;
input_param(2).UpperBound = 4;

input_param(3).Name = 'Hecate_param3';
input_param(3).LowerBound = 0;
input_param(3).UpperBound = 4;

input_param(4).Name = 'Hecate_param4';
input_param(4).LowerBound = 0;
input_param(4).UpperBound = 4;

% Choose requirement
phi = 'hev1';

% Define options
hecateOpt = hecate_options;
hecateOpt.runs = 1;
hecateOpt.optim_params.n_tests = 20;
hecateOpt.sequence_scenario = '';
hecateOpt.assessment_scenario = '';

% Define other parameters
simulationTime = 400;
init_cond = [];

% Define S-Taliro parameters (for translation evaluation)
staliro_InputBounds = [0 100];
staliro_cp_array = [5];
staliro_SimulationTime = simulationTime;
hecateOpt.interpolationtype={'pchip'};
