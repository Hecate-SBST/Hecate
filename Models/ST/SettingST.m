% This script is used to define all the variables needed to run the ST
% benchmark on Hecate

% Call the global variables
global init_cond;
global simulationTime;

% Choose the model
model = 'SignalTracker';
toll = 1e-3;

% Write requirements in STL
phi = ['[]_[0,30] ((([]_[0,0.5] condMode0) -> ([]_[0.5,0.6] (predMode0_1 /\ predMode0_2))) /\',...
    '(([]_[0,0.5] (condMode1_1 /\ condMode1_2)) -> ([]_[0.5,0.6] predMode1)) /\',...
    '(([]_[0,0.5] condMode2) -> ([]_[0.5,0.6] predMode2)))'];

preds(1).str = 'condMode0';
preds(1).A = [0 0 1];
preds(1).b = 0.3;

preds(2).str = 'predMode0_1';
preds(2).A = [1 0 0];
preds(2).b = toll;

preds(3).str = 'predMode0_2';
preds(3).A = [-1 0 0];
preds(3).b = toll;

preds(4).str = 'condMode1_1';
preds(4).A = [0 0 -1];
preds(4).b = -0.7;

preds(5).str = 'condMode1_2';
preds(5).A = [0 0 1];
preds(5).b = 1.3;

preds(6).str = 'predMode1';
preds(6).A = [0 1 0];
preds(6).b = 2;

preds(7).str = 'condMode2';
preds(7).A = [0 0 -1];
preds(7).b = -1.3;

preds(8).str = 'predMode2';
preds(8).A = [0 1 0];
preds(8).b = 1;

% Hecate parameters
input_param(1).Name = 'Hecate_Phase1';
input_param(1).LowerBound = 2;
input_param(1).UpperBound = 8;

input_param(2).Name = 'Hecate_Amp1';
input_param(2).LowerBound = 1;
input_param(2).UpperBound = 2;
%input_param(2).UpperBound = 5;

input_param(3).Name = 'Hecate_Freq1';
input_param(3).LowerBound = 0.1;
input_param(3).UpperBound = 1;

input_param(4).Name = 'Hecate_Amp2';
input_param(4).LowerBound = 1;
input_param(4).UpperBound = 5;

input_param(5).Name = 'Hecate_Freq2';
input_param(5).LowerBound = 0.1;
input_param(5).UpperBound = 1;

% Define options
hecateOpt = hecate_options;
hecateOpt.runs = 50;
hecateOpt.optim_params.n_tests = 300;
hecateOpt.sequence_scenario = '';
hecateOpt.assessment_scenario = 'Requirement';

% Define other parameters
simulationTime = 30;
init_cond = [];

% Define S-Taliro parameters
staliro_InputBounds = [-5 5; -0.5 2.5];
staliro_cp_array = [6, 6];
staliro_SimulationTime = simulationTime;
hecateOpt.interpolationtype={'pchip','pconst'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Signal~[/]$', '$Tracking~mode~[/]$'};
output_data.range = [-5, 5; -10, 10; 0, 2];
output_data.name = {'$Tracked~signal~[/]$', '$Tracking~error~[/]$', '$Tracking~mode~[/]$'};

assignin('base','toll',toll)