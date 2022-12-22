% This script is used to define all the variables needed to run the WT
% benchmark on Hecate

% Call the global variables
global init_cond;
global simulationTime;

% Choose the model
model = 'windturbine';

% Write requirements
wt1 = '[]_[30,630] (wt1pred)';
wt2 = '[]_[30,630] (wt2pred1 /\ wt2pred2)';
wt3 = '[]_[30,630] (wt3pred)';

preds(1).str = 'wt1pred';
preds(1).A = [0 0 0 0 0 1];
preds(1).b = 14.2;

preds(2).str = 'wt2pred1';
preds(2).A = [0 0 -1 0 0 0];
preds(2).b = -21000;

preds(3).str = 'wt2pred2';
preds(3).A = [0 0 1 0 0 0];
preds(3).b = 47500;

preds(4).str = 'wt3pred';
preds(4).A = [0 0 0 0 1 0];
preds(4).b = 14.3;

% Hecate parameters
input_param(1).Name = 'Hecate_wind1';
input_param(1).LowerBound = 8;
input_param(1).UpperBound = 16;

input_param(2).Name = 'Hecate_mean2';
input_param(2).LowerBound = 10;
input_param(2).UpperBound = 14;

input_param(3).Name = 'Hecate_amp2';
input_param(3).LowerBound = 3;
input_param(3).UpperBound = 4;

input_param(4).Name = 'Hecate_freq2';
input_param(4).LowerBound = 10;
input_param(4).UpperBound = 20;

% Name of active scenarios
activeScenarioTA = 'WT2';
activeScenarioTS = 'WT2';
phi = wt2;

% Define options
staliro_opt = staliro_options;
staliro_opt.optim_params.n_tests = 300;
staliro_opt.SampTime=0.01;

% Define other parameters
simulationTime = 630;
init_cond = [];

% Define S-Taliro parameters
staliro_InputBounds = [8, 16];       % Inside the model, 8  is added to the S-Taliro input, so the actual range is [8,16]
staliro_cp_array = 126;
staliro_SimulationTime = simulationTime;
staliro_opt.interpolationtype={'pchip'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Wind~speed$'};
output_data.range = [0, 15; 2, 3; 20000, 50000; 900, 1400; 9, 15; 0, 15];
output_data.name = {{'$Demanded~blade$','$pitch~angle$'}, '$Region$', '$Generator~torque$', ...
    '$Generator~speed$', '$Blade~speed$', '$Blade~pitch~angle$'};

% Run script to set up the model
init_SimpleWindTurbine;
assignin('base','Parameter',Parameter)
assignin('base','cP_modelrm',cP_modelrm)
assignin('base','cT_modelrm',cT_modelrm)
