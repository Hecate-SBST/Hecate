% This script is used to define all the variables needed to run the
% Pacemaker benchmark on Hecate.

global init_cond;
global simulationTime;

% Choose the model
model = 'Model2_Scenario1_Faulty';

phi = '[]_[0,10] ventPWM_limit';

% Note: Since LRL is changing, we need to create three separate requirements.

preds(1).str = 'ventPWM_limit';
preds(1).A = 1;
preds(1).b = 100;

% Hecate params
input_param(1).Name = 'Hecate_Amp1';
input_param(1).LowerBound = 1;
input_param(1).UpperBound = 5;

input_param(2).Name = 'Hecate_Amp2';
input_param(2).LowerBound = 1;
input_param(2).UpperBound = 5;

input_param(3).Name = 'Hecate_Amp3';
input_param(3).LowerBound = 1;
input_param(3).UpperBound = 5;

input_param(4).Name = 'Hecate_Mode2';
input_param(4).LowerBound = 0;
input_param(4).UpperBound = 3.99;

% Define options
hecateOpt = hecate_options;
hecateOpt.runs = 50;
hecateOpt.optim_params.n_tests = 300;
hecateOpt.sequence_scenario = '';
hecateOpt.assessment_scenario = '';

% Define other parameters
simulationTime = 15;
init_cond = [];

% S-Taliro parameters
staliro_InputBounds = [1, 5; 0, 3.99];
staliro_cp_array = [3, 2];
staliro_SimulationTime = simulationTime;
hecateOpt.interpolationtype={'pchip','pconst'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Vent~Amplitude~[V]$', '$Mode~[/]$'};
output_data.range = [0 140];
output_data.name = {'$Vent~PWM~reference~[\%]$'};
