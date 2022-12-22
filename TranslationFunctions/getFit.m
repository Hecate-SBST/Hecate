function [stepTable_new, fitTable] = getFit(stepTable)
% This function evaluates how to compute the fitness value for each
% verify or assert statement.
%
%               [stepTable_new, fitTable] = getFit(stepTable)
%
% Input:
%   stepTable: Table containing the sorted data on each assessments step.
%
% Output:
%   stepTable_new: Same structure as stepTable, but containing also a cell
%   array containing the name of all the fitness values evaluated in that
%   step.
%
%   fitTable: Table containing the name of each fitness value, the formula
%   to compute it and the step that contains the corresponding verify
%   statement.

global verifyCount;
verifyCount = 0;

% Add FitName fields to stepTable
stepTable_new = stepTable;
stepTable_new.FitName = cell(size(stepTable,1),1);

% Create fitTable
fitStruct = [];

% Look for 'verify' statements
for ii = 1:size(stepTable,1)

    stepLine = stepTable(ii,:);

    if ~isempty(stepLine.Action{1})
        % Remove comments
        verifyStatement = regexp(stepLine.Action{1},'(?m)^([^%]+)','match');
        verifyStatement = join(verifyStatement);
    
        % Isolate the single verify or assert statements
        verifyStatement = erase(char(verifyStatement), {' ',sprintf('\t')});
        verifyStatement = regexp(verifyStatement,'(?m)^(?:verify|assert)\((\S+?)\)(?:%\S+|;|)$','tokens');

        % Go to the next step if the current one does not contain any
        % verify or assert statement
        if isempty(verifyStatement)
            continue
        end
    else
        continue
    end

    % Check each verify or assert statement
    fitName_temp = cell(length(verifyStatement),1);
    
    for jj = 1:length(verifyStatement)
        
        statement_temp = verifyStatement{jj};

        % Remove the warning message at the end of the verify or assert
        % statement (if it is present).
        statement_temp = split(statement_temp,',''');
        statement_temp = statement_temp{1};

        % Create the name of the fitness value
        verifyCount = verifyCount+1;
        fitName_temp{jj} = sprintf('fitness_%i',verifyCount);

        % Convert the verify or assert statement into a fitness function
        if strcmp(statement_temp,'true')
            % Convert verify(true) and assert(true)
            fitFunc_temp = '1';
        elseif strcmp(statement_temp,'false')
            % Convert verify(false) and assert(false)
            fitFunc_temp = '-1';
        elseif xor(contains(statement_temp,'&'), contains(statement_temp,'|'))
            % ToDo: Check that the expression doesn't contain logical
            % negation and parenthesis.
            
            % Convert series of AND or OR conditions
            if contains(statement_temp,'&')
                operator = 'min';
            else
                operator = 'max';
            end
            listAtomPred = split(statement_temp,{'&','|'});
            listAtomPred = listAtomPred(~cellfun('isempty',listAtomPred));
            fitFunc_temp = [operator,'(['];
            for kk = 1:length(listAtomPred)
                fitFunc_temp = [fitFunc_temp, convertAtomPred(listAtomPred{kk}), ';'];
            end
            fitFunc_temp = [fitFunc_temp,'])'];

        elseif contains(statement_temp,{'<','>','==','~='}) && ~contains(statement_temp,{'&','|','hasChanged'})
            % Convert a single atomic predicates
            fitFunc_temp = convertAtomPred(statement_temp);
        else
            % Return error for not supported expressions
            error('The verify or assert statement ''%s'' is not supported.',statement_temp)
        end

        % Add new line to the fitTable
        fitLine.Name = fitName_temp{jj};
        fitLine.Func = fitFunc_temp;
        fitLine.Step = stepLine.Name{1};

        fitStruct = [fitStruct; fitLine];

    end

    % Save the data in stepTable_new
    idx = strcmp({fitStruct.Step},stepLine.Name);
    stepLine.FitName = {{fitStruct(idx).Name}};
    stepTable_new(ii,:) = stepLine;

end

% Convert fitStruct into a table variable
if isempty(fitStruct)
    error('The Test Assessment block does not contain any verify or assert statements, so it is impossible to obtain a fitness function definition.')
end
fitTable = struct2table(fitStruct,'AsArray',true);

end