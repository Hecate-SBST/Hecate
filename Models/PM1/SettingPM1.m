% This script is used to define all the variables needed to run the
% Pacemaker benchmark on Hecate.

global init_cond;
global simulationTime;

% Choose the model
model = 'Model1_Scenario1_Correct';

% Write requirements in STL
phi = '([]_[0,10] max_beats) /\ (<>_[0,10] min_beats)';

% Atomic predicates
preds(1).str = 'max_beats';
preds(1).A = [0 0 1];   % Selecting for the PACE_COUNT output
preds(1).b = 15;        % One 6th of the upper range of LRL (90)

preds(2).str = 'min_beats';
preds(2).A = [0 0 -1];   % Selecting for the PACE_COUNT output
preds(2).b = -8;        % Floor of one 6th of the lower range of LRL (50)

% Hecate params
input_param(1).Name = 'Hecate_lrl1';
input_param(1).LowerBound = 50;
input_param(1).UpperBound = 65;

input_param(2).Name = 'Hecate_lrl2';
input_param(2).LowerBound = 50;
input_param(2).UpperBound = 65;

input_param(3).Name = 'Hecate_lrl3';
input_param(3).LowerBound = 50;
input_param(3).UpperBound = 65;

input_param(4).Name = 'Hecate_lrl4';
input_param(4).LowerBound = 50;
input_param(4).UpperBound = 65;

input_param(5).Name = 'Hecate_lrl5';
input_param(5).LowerBound = 50;
input_param(5).UpperBound = 65;

% Define options
hecateOpt = hecate_options;
hecateOpt.runs = 50;
hecateOpt.optim_params.n_tests = 300;
hecateOpt.sequence_scenario = '';
hecateOpt.assessment_scenario = 'EndCheck';

% Define other parameters
simulationTime = 10;
init_cond = [];

% S-Taliro parameters
staliro_InputBounds = [50 90];
staliro_cp_array = 5;
staliro_SimulationTime = simulationTime;
hecateOpt.interpolationtype={'pchip'};

input_data.range = staliro_InputBounds;
input_data.name = {'$LRL~[bpm]$'};
output_data.range = [600 1300; 40 100; -3 18];
output_data.name = {'$Period~[ms]$', '$LRL~[bpm]$', '$Pace~Count~[/]$'};
