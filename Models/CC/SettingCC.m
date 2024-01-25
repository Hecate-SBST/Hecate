% This script is used to define all the variables needed to run the CC
% benchmark on Hecate

% Call the global variables
global init_cond;
global simulationTime;

% Choose the model
model = 'carsmodel';

% Write requirements
cc1 = '[]_[0,100] (cc1pred)';
ccx = '([]_[0,50] (ccxpred1)) /\ ([]_[0,50] (ccxpred2)) /\ ([]_[0,50] (ccxpred3)) /\ ([]_[0,50] (ccxpred4))';  

preds(1).str='cc1pred';
preds(1).A = [0 0 0 -1 1];
preds(1).b = 40;

preds(2).str='ccxpred1';
preds(2).A = [1 -1 0 0 0];
preds(2).b = -7.5;

preds(3).str='ccxpred2';
preds(3).A = [0 1 -1 0 0];
preds(3).b = -7.5;

preds(4).str='ccxpred3';
preds(4).A = [0 0 1 -1 0];
preds(4).b = -7.5;

preds(5).str='ccxpred4';
preds(5).A = [0 0 0 1 -1];
preds(5).b = -7.5;

% Hecate parameters
input_param(1).Name = 'Hecate_throttle1';
input_param(1).LowerBound = 0.5;
input_param(1).UpperBound = 0.66;

input_param(2).Name = 'Hecate_throttle2';
input_param(2).LowerBound = 0;
input_param(2).UpperBound = 0.4;

input_param(3).Name = 'Hecate_brake1';
input_param(3).LowerBound = 0.15;
input_param(3).UpperBound = 0.6;

input_param(4).Name = 'Hecate_brake2';
input_param(4).LowerBound = 0;
input_param(4).UpperBound = 0.4;

input_param(5).Name = 'Hecate_freq';
input_param(5).LowerBound = 0;
input_param(5).UpperBound = 1;

input_param(6).Name = 'Hecate_trigger';
input_param(6).LowerBound = 20;
input_param(6).UpperBound = 80;

% Choose requirement
phi = cc1;

% Define options
hecateOpt = hecate_options;
hecateOpt.runs = 50;
hecateOpt.optim_params.n_tests = 300;
hecateOpt.fals_at_zero = 0;
hecateOpt.sequence_scenario = '';
hecateOpt.assessment_scenario = 'CC1';

% Define other parameters
simulationTime = 100;
init_cond = [];

% Define S-Taliro parameters
staliro_InputBounds = [0 0.85; 0.15 1];
staliro_cp_array = [7, 3];
staliro_SimulationTime = simulationTime;
hecateOpt.interpolationtype={'pchip','pchip'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Throttle$', '$Brake$'};
output_data.range = [-200, 100; -200, 100; -200, 100; -200, 100; -200, 100];
output_data.name = {'$Position~car~1$', '$Position~car~2$', '$Position~car~3$', '$Position~car~4$', '$Position~car~5$'};