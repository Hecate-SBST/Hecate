% This script is used to define all the variables needed to run the
% Pacemaker benchmark on Hecate.

global init_cond;
global simulationTime;

% Choose the model
model = 'Pacemaker_3MD3_Group1';

% Write requirements in STL
% phi = ['[]_[0,20) (([]_[0,0.001] predMode) -> (<>_[0.001,2.001] (predDetect \/ predControl))) /\', ...
%     '[]_[20,40) (([]_[0,0.001] predMode) -> (<>_[0.001,1.001] (predDetect \/ predControl))) /\', ...
%     '[]_[40,60] (([]_[0,0.001] predMode) -> (<>_[0.001,0.501] (predDetect \/ predControl)))'];

phi = '[]_[0,59] (([]_[0,0.001] predMode) -> (<>_[0.001,1.002] (predDetect \/ predControl)))';

% Note: Since LRL is changing, we need to create three separate requirements.

preds(1).str = 'predMode';
preds(1).A = [0 0 -1 0];
preds(1).b = -2.5;

preds(2).str = 'predDetect';
preds(2).A = [0 0 0 -1];
preds(2).b = -0.6;

preds(3).str = 'predControl';
preds(3).A = [-1 0 0 0];
preds(3).b = -0.7;

% Hecate params
input_param(1).Name = 'Hecate_HeartFail';
input_param(1).LowerBound = 20;
input_param(1).UpperBound = 60;

input_param(2).Name = 'Hecate_delayOn';
input_param(2).LowerBound = -1.5;
input_param(2).UpperBound = 1;

input_param(3).Name = 'Hecate_delayOff';
input_param(3).LowerBound = -0.045;
input_param(3).UpperBound = 0.05;

input_param(4).Name = 'Hecate_Mode';
input_param(4).LowerBound = -0.5;
input_param(4).UpperBound = 3.5;

% Name of active scenarios
activeScenarioTA = 'Partial';
activeScenarioTS = '';

% Define options
staliro_opt = staliro_options;
staliro_opt.fals_at_zero = 0;
staliro_opt.optim_params.n_tests = 300;
staliro_opt.SampTime = 0.01;

% Define other parameters
simulationTime = 60;
init_cond = [];

% S-Taliro parameters
staliro_InputBounds = [-0.5 3.5; 0 0.60];
staliro_cp_array = [1, 13];
staliro_SimulationTime = simulationTime;
staliro_opt.interpolationtype={'const','pchip'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Mode~[/]$', '$Atr~Pulse~Detect~[T/F]$'};
output_data.range = [0 1; 0 3; 0 1];
output_data.name = {'$Atr~Pulse~Control~[T/F]$', '$Mode~[/]$', '$Atr~Pulse~Detect~[T/F]$'};
