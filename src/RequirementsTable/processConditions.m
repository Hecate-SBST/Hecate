function conditions = processConditions(conditions, headers)
    
    %conditions = conditions(~cellfun('isempty', conditions));
    
    
    conditions = cellfun(@(x) ['(', x, ')'], conditions, 'UniformOutput', false);

    reg_ex = '(?<![a-zA-Z0-9])X(?![a-zA-Z0-9])';
    operators = {'<=', '>=', '==', '~=', '<', '>'};
    rangePattern = '([\(\[])(.*?), (.*?)([\)\]])';

    bracketFlag = false;
    incompleteEquality = false;

    % Finds "X" in the Preconditions and replaces it with the headerX
    for jj = 1:length(conditions)
       
        

        conditions{jj} = regexprep(conditions{jj}, ' ', '');
        str = conditions{jj}(2:end-1);

        if isempty(str)
            continue
        end

        % Split the string at every comma outside brackets
        splitStr = regexp(str, ',(?![^()]*\))', 'split');

        if (conditions{jj}(2) == '(' || conditions{jj}(2) == '[') && (conditions{jj}(end-1) == ')' || conditions{jj}(end-1) == ']')
            % Display the split parts
            if str(1) == '('
                lowerOperator = '>';
            elseif str(1) == '['
                lowerOperator = '>=';
            else
                error('Invalid lower bound bracket');
            end

            if str(end) == ')'
                upperOperator = '<';
            elseif str(end) == ']'
                upperOperator = '<=';
            else
                error('Invalid upper bound bracket');
            end

            lowerExpression = [headers{jj}, lowerOperator, ' ', splitStr{1}(2:end)];
            upperExpression = [headers{jj}, upperOperator, ' ', splitStr{2}(1:end-1)];

            conditions{jj} = ['(', lowerExpression, ' && ', upperExpression, ')'];
            bracketFlag = true;
            continue
        end

        isMatch = ~isempty(regexp(conditions{jj}, reg_ex, 'once'));
        replace = headers{jj};

        if isMatch
            conditions{jj} = regexprep(conditions{jj}, reg_ex, replace);
            continue
        end

        if ismember(conditions{jj}(2), operators) % Incomplete Relationship Operations
            conditions{jj} = [conditions{jj}(1), headers{jj}, conditions{jj}(2:end)];
            incompleteEquality = true;
            continue
        end

        if ~any(cellfun(@(x) any(ismember(conditions{jj}, x)), operators))
            for kk = 1:length(splitStr)
                splitStr{kk} = [headers{jj}, ' == ', splitStr{kk}];
            end
            conditions(jj) = join(splitStr, ' && ');
        end
    end
end
    

