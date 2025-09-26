% This function takes in a requirement column or columns in which a header 
% can be specified. It then reformats the requirement so that it can be
% read correctly and placed into a Stateflow
function conditions = processHeaders(conditions, headers)
    
    %defines information to differentiate different uses of headers 
    reg_ex = '(?<![a-zA-Z0-9])X(?![a-zA-Z0-9])';
    operators = {'<=', '>=', '==', '~=', '<', '>'};
    rangePattern = '([\(\[])(.*?), (.*?)([\)\]])';

   
    %Adds brackets to the conditions to ensure proper order of evaluation
    conditions = cellfun(@(x) ['(', x, ')'], conditions, 'UniformOutput', false);


    for jj = 1:length(conditions)
        conditions{jj} = regexprep(conditions{jj}, ' ', '');
        str = conditions{jj}(2:end-1);

        %Case one: Finds an empty condition
        if isempty(str)
            continue
        end


        % Split the string at every comma outside brackets
        splitStr = regexp(str, ',(?![^()]*\))', 'split');

        % Case two: Finds a range specified by brackets
        if (conditions{jj}(2) == '(' || conditions{jj}(2) == '[') && ...
                (conditions{jj}(end-1) == ')' || conditions{jj}(end-1) == ']')
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
            continue
        end

        % Case three: Finds case for placeholder "X"
        isMatch = ~isempty(regexp(conditions{jj}, reg_ex, 'once'));
        replace = headers{jj};

        if isMatch
            conditions{jj} = regexprep(conditions{jj}, reg_ex, replace);
            continue
        end

        % Case four: Finds incomplete relationship expressions
        if ismember(conditions{jj}(2), operators) 
            conditions{jj} = [conditions{jj}(1), headers{jj}, conditions{jj}(2:end)];
            continue
        end


        % Case five: Finds a value or a list of values that are to be
        % equated to the header
        if ~any(cellfun(@(x) any(ismember(conditions{jj}, x)), operators))
            for kk = 1:length(splitStr)
                splitStr{kk} = [headers{jj}, ' == ', splitStr{kk}];
            end
            conditions(jj) = join(splitStr, ' && ');
        end
    end
end
    

