function input_param_new = checkTestSequenceParameter(blockPath,input_param,stepTable,transTable)
% This function checks that all the parameters listed in the input_range
% struct array start with Hecate and that all the parameters used in the
% Test Sequence block that start with Hecate are also present in the
% input_range struct array.
%
%               paramList = checkTestSequenceParameter(blockPath,input_range);
%
%   E.g.:       paramList = checkTestSequenceParameter('vdp/Test Sequence',input_range);
%
% Input:
%   blockPath: char array containing the path to the Test Sequence block.
%
%   input_range: struct array containing the Name, Lower Bound and Upper
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
%   input_range_new: same structure as input_range, but containing only the
%   parameters

% Convert struct array to table
input_table = struct2table(input_param);

% Checks that all the parameter name in input_table start with 'Hecate'
idx_input = regexp(input_table.Name,'Hecate','once');

if any(cellfun(@isempty,idx_input)) || any(cell2mat(idx_input) ~= 1)
    error('Incorrect parametertab name. All parameter names should start with ''Hecate''.')
end

% Get all the parameters name
paramTS = sltest.testsequence.findSymbol(blockPath, 'Scope', 'Parameter');
input_param_new = [];

% Loop over all the Test Sequence parameter
for ii = 1:length(paramTS)

    idx_temp = regexp(paramTS{ii},'Hecate','once');

    % Skip all the parameters that do not contain the word 'Hecate' or
    % contain it not at the beginning of the name.
    if isempty(idx_temp) || idx_temp > 1
        continue
    end

    % Check that the parameter is mentioned in the steps or transitions of
    % the actual scenario.
    if any(contains(stepTable.Action,paramTS{ii}))
        idx = strcmp(paramTS{ii},input_table.Name);
        input_param_new = [input_param_new, input_param(idx)];
    elseif ~isempty(transTable) && any(contains(transTable.Condition,paramTS{ii}))
        idx = strcmp(paramTS{ii},input_table.Name);
        input_param_new = [input_param_new, input_param(idx)];
    else
        warning(['The parameter %s is not used in the currently active Test Sequence scenario,' ...
            ' therefore it will be ignored by the input generation process.'],paramTS{ii})
    end

end

end