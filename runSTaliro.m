function runSTaliro(settingName)
% This function runs S-Taliro on a model according to a given setting file
% and save automatically the results.
%
%           runSTaliro(settingName);
%
%   E.g.:   runSTaliro("SettingAT");
%
% Inputs:
%   settingName: char array or string containing the name of the Setting
%   file. This file must contain all the parameters necessary to run
%   S-Taliro on the associated model.
%   Note: The model name should not contain the file extension: 'SettingAT'
%   is ok, but 'SettingAT.m' is not.
%
% (C) 2022, Federico Formica, Tony Fan, McMaster University
% (C) 2024, Federico Formica, McMaster University

    %% Preliminary operations and declare model parameters
    
    % Turn off warning if verify is falsified
    warning off Stateflow:Runtime:TestVerificationFailed
    
    % Turn off warning if the fitness value is Inf
    warning off Simulink:Engine:BlockOutputInfNanDetectedError
    
    % Turn off warning for unused symbols in Test Sequence and Test Assessment
    warning off Stateflow:reactive:UnusedDataInReactiveTestingTableChart
    warning off Stateflow:cdr:UnusedDataOrEvent
    
    % Turn off warning for imposed equality inside verify
    warning off Stateflow:cdr:VerifyDangerousComparison
    
    % Turn off warning for rmpath in Directory Not Found
    warning off MATLAB:rmpath:DirNotFound
    
    % Add folders to the path
    addpath("src")
    rmpath("src/robustness_Hecate")
    addpath("src/robustness_Staliro")
    addpath(genpath("Models"))
    addpath(genpath("staliro"))

    % Set the RNG seed to a random value
    rng("shuffle")

    % Define Hecate input variables.
    % global SettingFile;
    if exist(settingName,"file") == 2
        % SettingFile = settingName;
        eval(settingName);  %setting model file
    else
        error("There is no Setting file in the current workpath with the given name.")
    end

    %% Run S-Taliro

    % Remove Fitness Converter blocks
    hecateOpt = cleanModel(model,input_param,hecateOpt);

    % Run S-Taliro
    [Results, History, Options] = staliro(model,init_cond,staliro_InputBounds,staliro_cp_array,phi,preds,simulationTime,hecateOpt);
    
    %% Save results

    tool = "S-Taliro";

    % Create save files folder if it doesn't exist
    if ~isfolder("TestResults")
        mkdir("TestResults")
    end
    
    % Define saving file name
    fileStr = string(datetime("now","Format","dd_MM_yy_HHmm"));
    if contains(settingName,"setting","IgnoreCase",true)
        nameStr = erase(settingName,["Setting","setting"]);
        fileStr = "./TestResults/STaliro_" + nameStr + "_" + fileStr + ".mat";
    else
        fileStr = "./TestResults/STaliro_" + model + "_" + fileStr + ".mat";
    end

    % Save results
    save(fileStr);
    fprintf("\nResults were saved in %s.\n",fileStr);

end