function transTable = getAllTrans(stepTable, blockPath)
% This function reads all the available transitions from the Test
% Assessment block.
% This function needs to be always run after sorting the assessments,
% otherwise the transitions will not be in order.
%
%           transTable = getAllTrans(stepTable, blockPath);
%
%   E.g.:   transTable = getAllTrans(stepTable, 'vdp/Test Assessment');
%
% Input:
%   stepTable: Table containing the sorted data on each assessments step.
%
%   blockPath: char array containing the path to the Test Sequence or Test
%   Assessment block.
%
% Output:
%   transTable: Table containing the sorted data on each transition.

transTable = table();

for ii  = 1:size(stepTable,1)

    stepLine = stepTable(ii,:);

    % Read proper transitions
    for jj = 1:stepLine.TransitionCount
        transTemp = sltest.testsequence.readTransition(blockPath,char(stepLine.Name),jj);
        transTemp.Step = string(transTemp.Step);
        transTemp.NextStep = string(transTemp.NextStep);
        if isempty(transTemp.Condition)
            transTemp.Condition = "true";
        else
            transTemp.Condition = string(transTemp.Condition);
        end
        transTable = [transTable; struct2table(transTemp)];
    end

end

% If transTable is empty create the fields manually
if isempty(transTable)
    transTable = cell2table(cell(0,4),'VariableNames',{'Step','Index','NextStep','Condition'});
else
    % Convert transTable.Step, .Condition and .NextStep from String to Char
    transTable.Step = cellstr(transTable.Step);
    % transTable.Index = transTable.Index;
    transTable.NextStep = cellstr(transTable.NextStep);
    transTable.Condition = cellstr(transTable.Condition);
end

end