%% init_SimpleWindTurbine
% (C) 2019 Decyphir SAS (C) 2015 General Electic Global Research - all rights reserved

%% ========================================================================
%clear all
%close all
%clc

SimplifiedTurbine_Config;

% add some paths
 addpath('Models/WT/tools/')
 addpath('Models/WT/wind/')
 addpath(config.wafo_path)

%load wind files
load('ClassA.mat')
load('ClassA_config.mat')
load('aeromaps3.mat');

% remove all unnecessary fields (otherwise Simulink will throw an error)
cT_modelrm = rmfield(cT_model,{'VarNames'});%,'RMSE','ParameterVar','ParameterStd','R2','AdjustedR2'});
cP_modelrm = rmfield(cP_model,{'VarNames'});%,'RMSE','ParameterVar','ParameterStd','R2','AdjustedR2'});

% initialize WAFO
initwafo

Parameter.InitialConditions = load('InitialConditions');
Parameter.Time.TMax                 = 630;            % [s]       duration of simulation
% Parameter.Time.dt                   = 0.01;           % [s]       time step of simulation
Parameter.Time.dt                   = 0.1;           % [s]       time step of simulation
Parameter.Time.cut_in               = 30;


iBin = find(URefVector==Parameter.URef);
iRandSeed = 1;

config.iBin                         = iBin;
config.iRandSeed                    = iRandSeed;
Parameter.v0                        = v0_cell{iBin,iRandSeed};
Parameter.v0.signals.values         = Parameter.v0.signals.values';
Parameter.TMax                      = v0_cell{iBin,iRandSeed}.time(end);
config.WindFieldName                = FileNames{iBin,iRandSeed};
% Time
Parameter.Time.cut_out              = Parameter.Time.TMax;
Parameter.v0_0 = Parameter.v0.signals.values(1);

Parameter = SimplifiedTurbine_ParamterFile(Parameter);

