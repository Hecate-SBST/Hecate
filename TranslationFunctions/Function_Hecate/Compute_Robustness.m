function [cost, ind, cur_par, rob, otherData] = Compute_Robustness(input, auxData)
% This function computes the robustness of the system using the Stateflow
% Chart model.

%% Global declarations and I/O
global staliro_InputModel;
global staliro_InputModelType;
global staliro_SimulationTime;
global staliro_opt;
input_search = getappdata(0,'input_search');%because global input_search wasn't working

% Read-Write global declarations (not used in parallel executions, i.e., within parfor loops)
global staliro_timeStats;

if nargin<2
    auxData = StaliroRobustnessAuxData;
    auxData.timeStats.warnings(false);
else
    assert(isa(auxData,'StaliroRobustnessAuxData'), '     Compute_Robustness expects a StaliroRobustnessAuxData object for auxiliary data.');
end

% Save simulation time
otherData = struct('timeStats',[]);
otherData.timeStats = struct('simTimes',[],'robTimes',[]);

% Check whether we need to collect time stats and whether this will be
% placed in a global variable or not. If the parallel toolbox is used, then
% the data cannot be collected in the global variable.
if staliro_opt.TimeStatsCollect
    isOnWorker = ~isempty(getCurrentTask()); % Check for parfor loop
    if isOnWorker
        % Compute_robustness is called from within a parfor loop
        % We need to collect local data and pass it to the calling optimizer
        % The optimizer has the responsibility of correctly collecting the
        % overall data over each parallel execution.
        assert(auxData.timeStats.CollectingData, fprintf(' S-TaLiRo: Time statistics collection is requested (the property TimeStatsCollect is true) \n within a parfor loop, but the optimizer is not collecting the data. \n See readme.txt in the optimization folder. \n'));
    end
end

warning('off','Simulink:Logging:LegacyModelDataLogsFormat');

%% Run the model and compute the fitness value or robustness

% Split the initial conditions from the input perturbances
idx_init_cond = length(input)-length(input_search);
init_cond = input(1:idx_init_cond);
input = input(idx_init_cond+1:end);

% Update the Hecate variables
for ii = 1:length(input)
    assignin('base',input_search(ii).Name,input(ii));
end

% Simulate the model
if strcmp(staliro_InputModelType,'function_handle')
    simTimeStart = tic;
    y_out = feval(staliro_InputModel,init_cond,staliro_SimulationTime,[],[]);
    otherData.timeStats.simTimes = toc(simTimeStart);

elseif strcmp(staliro_InputModelType,'simulink')

    simopt = simget(staliro_InputModel);
    if ~isempty(init_cond)
        simopt = simset(simopt, 'InitialState', init_cond);
    end

    simTimeStart = tic;
    simOut = sim(staliro_InputModel,[0, staliro_SimulationTime],simopt);
    % [t_out,y_out] = sim(staliro_InputModel,[0, staliro_SimulationTime],simopt);
    otherData.timeStats.simTimes = toc(simTimeStart);

    y_out = simOut.(get_param(staliro_InputModel,'OutputSaveName'));
else
    error('Model type not supported. Currently Hecate supports only Simulink models.')
end

% Define the final fitness value
if isa(y_out,'struct')
    %Simulation output as Structure or Structure with Time
    y_out = [y_out.signals.values];
    cost = y_out(end,end);
    min_cost = min(y_out(:,end));

elseif isa(y_out,'Simulink.SimulationData.Dataset')
    % Simulation output as Dataset
    cost = y_out{end};
    cost = cost.Values.Data;
    min_cost = min(cost);
    cost = cost(end);

else
    % Simulation output as Array
    cost = y_out(end,end);
    min_cost = min(y_out(:,end));

end

if min_cost < cost
    warning('The delay block in Simulink has skipped some value.')
    cost = min_cost;
end

% Store timing statistics
otherData.timeStats.robTimes = 0;
if staliro_opt.TimeStatsCollect
    staliro_timeStats.addSimTime(otherData.timeStats.simTimes);
    staliro_timeStats.addRobTime(otherData.timeStats.robTimes);
end

% Other outputs
ind = 1;
cur_par = [];
rob = cost;

end