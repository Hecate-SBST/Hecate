function inputParamNew = checkTestSequenceParameter(blockPath,inputParam,stepTable,transTable)
% This function checks that all the parameters listed in the input_range
% struct array start with Hecate and that all the parameters used in the
% Test Sequence block that start with Hecate are also present in the
% input_range struct array.
%
%               paramList = checkTestSequenceParameter(blockPath,input_range);
%
%   E.g.:       paramList = checkTestSequenceParameter("vdp/Test Sequence",input_range);
%
% Input:
%   blockPath: char array containing the path to the Test Sequence block.
%
%   inputParam: struct array containing the Name, Lower Bound and Upper
%   Bound for each Hecate parameter
%       input_range(1).Name = 'Hecate_param1';
%       input_range(1).LowerBound = 0;
%       input_range(1).UpperBound = 1;
%
%   stepTable: table containing the information on the all the steps of the
%   Test Sequence block.
%
%   transTable: table containing the information on the all the transitions
%   of the Test Sequence block.
%
% Output:
%   inputParamNew: same structure as input_range, but containing only the
%   parameters
%
% (C) 2022, Federico Formica, Tony Fan, McMaster University
% (C) 2024, Federico Formica, McMaster University

% Convert struct array to table
inputTable = struct2table(inputParam);

% Checks that all the parameter name in inputParam start with 'Hecate'
idxInput = regexp(inputTable.Name,"Hecate","once");

if any(cellfun(@isempty,idxInput)) || any(cell2mat(idxInput) ~= 1)
    error("Incorrect parameter name. All parameter names should start with 'Hecate'.")
end

% Get all the parameters name
paramTS = sltest.testsequence.findSymbol(blockPath, "Scope", "Parameter");
inputParamNew = [];

% Loop over all the Test Sequence parameter
unusedParameters = [];

for ii = 1:length(paramTS)

    idxTemp = regexp(paramTS{ii},"Hecate","once");

    % Skip all the parameters that do not contain the word 'Hecate' or
    % contain it not at the beginning of the name.
    if isempty(idxTemp) || idxTemp > 1
        continue
    end

    % Check that the parameter is mentioned in the steps or transitions of
    % the actual scenario.
    if any(contains(stepTable.Action,paramTS{ii}) | contains(stepTable.WhenCondition,paramTS{ii}))
        idx = strcmp(paramTS{ii},inputTable.Name);
        inputParamNew = [inputParamNew, inputParam(idx)];
    elseif ~isempty(transTable) && any(contains(transTable.Condition,paramTS{ii}))
        idx = strcmp(paramTS{ii},inputTable.Name);
        inputParamNew = [inputParamNew, inputParam(idx)];
    else
        unusedParameters = [unusedParameters; string(paramTS{ii})];
    end

end

% Show message for unused Test Sequence parameters
if ~isempty(unusedParameters)
    fprintf("The following Hecate parameters have been defined in the Test Sequence block\n" + ...
    "but they are not used by the active Test Sequence scenario, so they will be ignored.\n");
    for ii = 1:length(unusedParameters)
        fprintf("\t* %s\n",unusedParameters(ii));
    end
end

end