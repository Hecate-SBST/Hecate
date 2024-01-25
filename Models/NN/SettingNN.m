% This script is used to define all the variables needed to run the NN
% benchmark on Hecate

% Call the global variables
global init_cond;
global simulationTime;

% Choose the model
model = 'nn';

% Write requirements
phi = '(<>_[0,1] (!(nnxpred1))) /\ (<>_[1,1.5] ([]_[0,0.5] (!(nnxpred2) /\ nnxpred3))) /\ ([]_[2,3] (!(nnxpred4) /\ nnxpred5))';
% phi = '[]_[2,3] (!(nnxpred4) /\ nnxpred5)';

preds(1).str='nnxpred1';
preds(1).A = [0 1];
preds(1).b = 3.2;

preds(2).str='nnxpred2';
preds(2).A = [0 1];
preds(2).b = 1.75;

preds(3).str='nnxpred3';
preds(3).A = [0 1];
preds(3).b = 2.25;

preds(4).str='nnxpred4';
preds(4).A = [0 1];
preds(4).b = 1.825;

preds(5).str='nnxpred5';
preds(5).A = [0 1];
preds(5).b = 2.175;

% Hecate parameters
input_param(1).Name = 'Hecate_Step1';
input_param(1).LowerBound = 2.05;
input_param(1).UpperBound = 2.15;

input_param(2).Name = 'Hecate_Delay1';
input_param(2).LowerBound = -0.5;
input_param(2).UpperBound = 0.5;

input_param(3).Name = 'Hecate_Amp2';
input_param(3).LowerBound = -0.15;
input_param(3).UpperBound = 0.15;

input_param(4).Name = 'Hecate_Freq2';
input_param(4).LowerBound = 0.1;
input_param(4).UpperBound = 1;

% Define options
hecateOpt = hecate_options;
hecateOpt.runs = 50;
hecateOpt.optim_params.n_tests = 300;
hecateOpt.sequence_scenario = '';
hecateOpt.assessment_scenario = 'NNx';

% Define other parameters
simulationTime = 5;
init_cond = [];

% Define S-Taliro parameters
staliro_InputBounds = [1.85 2.15];
staliro_cp_array = 6;
staliro_SimulationTime = simulationTime;
hecateOpt.interpolationtype={'pchip'};

input_data.range = staliro_InputBounds;
input_data.name = {'$Reference~position$'};
output_data.range = [-0.5, 2.5; 0, 5];
output_data.name = {'$Error^{*}$','$Position$'};

% Declare the variables used by the model
alpha = 0.005;
assignin('base','alpha',alpha)
beta = 0.03;
assignin('base','beta',beta)
u_ts = 0.01;                   % Electrical current sampling time
assignin('base','u_ts',u_ts)
