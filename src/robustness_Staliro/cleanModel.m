function staliroOptions = cleanModel(modelName,inputParam,staliroOptions)
% This function removes the Fitness Converter subsystem from the model (if
% it is present) and makes sure the S-Taliro options are consistent with
% the system output.
%
%           staliroOptions = cleanModel(modelName,inputParam,staliroOptions)
%
%   E.g.:   staliroOptions = cleanModel('vdp',inputParam,staliroOptions)
%
% Input:
%   modelName: char array or string containing the name of the Simulink
%   model under analysis.
%
%   inputParam: struct array containing information on the Hecate
%   parameters used in the Test Sequence. All the Hecate parameters used in
%   the Test Sequence must be specified, even if they are not used by the
%   current active scenario. For each parameter, this variable must contain
%   its name and the upper and lower bound (all Hecate parameters are
%   assumed to be real values by the search algorithm).
%       inputParam(1).Name = 'Hecate_param';
%       inputParam(1).LowerBound = 0;
%       inputParam(1).UpperBound = 10;
%
%   staliroOptions: object of type staliro_options. It contains information
%   on how to execute the search algorithm.
%
% Output:
%   staliroOptions: object of type staliro_options. It contains information
%   on how to execute the search algorithm.

% Load model
load_system(modelName)

% Remove Fitness Converter blocks
blockNames = ["FitnessConverter_Hecate"; "Min_Hecate"; "Outport_Fit_Hecate"; "Delay_Hecate"];
for ii = 1:length(blockNames)
    if getSimulinkBlockHandle(modelName + "/" + blockNames(ii)) > 0
        delete_block(modelName + "/" + blockNames(ii))
    end
end

% Remove broken lines
delete_line(find_system(modelName, "FindAll", "on", "Type", "line", "Connected", "off"))

% Check S-Taliro options
singleVarModel = strcmp(get_param(modelName,"ReturnWorkspaceOutputs"),"on");
if singleVarModel ~= staliroOptions.SimulinkSingleOutput
    staliroOptions.SimulinkSingleOutput = double(singleVarModel);
end

% Set all the manual switches to the Inports option.
% The manual switches are used to change the input signal source
% between Test Sequence and Inports.
switchOpt = Simulink.FindOptions("SearchDepth",1);
switchList = Simulink.findBlocksOfType(modelName,"ManualSwitch",switchOpt);
for ii = 1:length(switchList)
    set_param(switchList(ii),"sw","0")
end

% Creates Hecate parameters (prevents Test Sequence from throwing errors)
paramTemp = zeros(length(inputParam),1);
for ii = 1:length(inputParam)
    paramTemp(ii) = rand(1)*(inputParam(ii).UpperBound-inputParam(ii).LowerBound)+inputParam(ii).LowerBound;
    assignin("base",inputParam(ii).Name,paramTemp(ii));
end

% Save model
save_system(modelName);

end