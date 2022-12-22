% This script is used to define all the variables needed to run the EU
% benchmark on Hecate

global init_cond;
global simulationTime;

% Choose the model
model = 'euler321_12B';

% Write requirements in STL
toll = 0.01;
phi = '[]_[0,50] (prednorm1 /\ prednorm2) /\ (preddet1 /\ preddet2)';

preds(1).str = 'prednorm1';
preds(1).A = [0 1 -1];
preds(1).b = toll;

preds(2).str = 'prednorm2';
preds(2).A = [0 -1 1];
preds(2).b = toll;

preds(3).str = 'preddet1';
preds(3).A = [1 0 0];
preds(3).b = 1+toll;

preds(4).str = 'preddet2';
preds(4).A = [-1 0 0];
preds(4).b = -1+toll;

% Hecate parameters
input_param(1).Name = 'Hecate_phiRamp';
input_param(1).LowerBound = 0.1;
input_param(1).UpperBound = 5;

input_param(2).Name = 'Hecate_thetaFreq';
input_param(2).LowerBound = 0;
input_param(2).UpperBound = 25;

input_param(3).Name = 'Hecate_psiDelay';
input_param(3).LowerBound = 1;
input_param(3).UpperBound = 9;

input_param(4).Name = 'Hecate_VectX';
input_param(4).LowerBound = -0.5;
input_param(4).UpperBound = 0.5;

input_param(5).Name = 'Hecate_VectY';
input_param(5).LowerBound = -0.5;
input_param(5).UpperBound = 0.5;

input_param(6).Name = 'Hecate_VectZ';
input_param(6).LowerBound = 0.5;
input_param(6).UpperBound = 1;

% Name of active scenarios
activeScenarioTA = '';
activeScenarioTS = '';

% Define options
staliro_opt = staliro_options;
staliro_opt.optim_params.n_tests = 300;
staliro_opt.SampTime = 0.01;

% Define other parameters
simulationTime = 10;
init_cond = [];

% Define S-Taliro parameters
staliro_InputBounds = [0 2*pi; 0 pi; 0 2*pi; -1 1; -1 1; -1 1];
staliro_cp_array = [5, 5, 5, 1, 1, 1];
staliro_SimulationTime = simulationTime;
staliro_opt.interpolationtype={'pchip','pchip','pchip','const','const','const'};

input_data.range = staliro_InputBounds;
input_data.name = {'$\phi~[rad]$', '$\vartheta~[rad]$', '$\psi~[rad]$', '$V_{in~x}~[/]$', '$V_{in~y}~[/]$', '$V_{in~z}~[/]$'};
output_data.range = [0.9, 1.1; -20, 20; -20, 20];
output_data.name = {'$det(\underline{\underline{R}})~[/]$', '$\lVert \vec{V_{in}}\rVert~[/]$', '$\lVert \vec{V_{end}}\rVert~[/]$'};

% Define variables for the model
assignin('base','toll',toll)