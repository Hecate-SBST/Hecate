function newexp = buildExpressionTree(expression)


% Main script


if ~ischar(expression) %
    expression = convertStringsToChars(expression);
end

if isempty(expression) || all(ismember(expression, '()')) || all(ismember(expression, '(true)')) 
    newexp = "TOKEN_TRUE";
    return
elseif all(ismember(expression, '(false)')) %double check this later
    newexp = "TOKEN_FALSE";
    return
end


mainOperators = {'&&', '&', '||', '|', '~'};
inBracket = 0; %updates to determine depth of bracket
parentdepth = inf; %used to determine which boolean operator takes precedence, 
% a lower parentdepth means higher priiroty
op_index = NaN;%used to keep track of the placement of the main operator in the expression

%exp = struct('content', expression, 'parent', NaN); 
tree = [struct('content', expression, 'parent', NaN)];

count = 1;

while length(tree) >= count
    expression = tree(count).content;
    parent = 0;
    doubleflag = 0; %used to handle cases where the main oeprator is 2 characters instead of one

    for i = 1:length(expression)
        current = expression(i);
        if expression(i) == '('
            inBracket = inBracket +1;
        elseif expression(i) == ')'
            inBracket = inBracket -1;
        elseif expression(i) == '~'
            if inBracket < parentdepth
                parent = '~';
                parentdepth = 5 + 5*inBracket; % priority = operator priority + 5*bracketdepth
                op_index = i;
            end
        elseif doubleflag == 1
            doubleflag = 0;%used for && and ||
            %this condition skips scanning for the second character in
            %those operators
            continue
        elseif expression(i) == '&'
            if expression(i+1) == '&' & inBracket < parentdepth %for the && case, the inBracket condition ensures 
                %order of operations
                parent = '&&';
                parentdepth = 3 + 5*inBracket;
                op_index = i;
                doubleflag = 1;
            elseif inBracket < parentdepth 
                parent = '&';
                parentdepth = 1 + 5*inBracket;
                op_index = i;
            end
        elseif expression(i) == '|'
            if expression(i+1) == '|' & inBracket < parentdepth %for the || case, the inBracket condition ensures 
                %order of operations
                parent = '||';
                parentdepth = 4 + 5*inBracket;
                op_index = i;
                doubleflag = 1;
            elseif inBracket < parentdepth
                parent = '|';
                parentdepth = 2 + 5*inBracket;
                op_index = i;
            end
   
        end
    
    end

    % The following conditions help break an expression into a tree with a
    % Boolean Operator parent and two "expression" leaves
    % this procedure is now repeated on the leaves until the leaves are
    % devoid of Boolean Operators.

    if strcmp(parent, '&&') || strcmp(parent, '||') 
        left = struct('content', expression(1:op_index - 1), 'parent', count);
        right = struct('content', expression(op_index + 2:end), 'parent', count);
        tree(count).content = parent;
        tree = [tree, left, right];
    elseif parent ~= 0
        left = struct('content', expression(1:op_index - 1), 'parent', count);
        right = struct('content', expression(op_index + 1:end), 'parent', count);
        tree(count).content = parent;
        tree = [tree, left, right];
    end
    count = count +1;
end
count = length(tree);

while count > 0 
    tree(count).content = strip(tree(count).content);
    if strcmp(tree(count).content, '()')
        count = count - 1;
    else
        if ~strcmp(tree(count).content, '&&') && ~strcmp(tree(count).content,'&') && ~strcmp(tree(count).content, '||') && ~strcmp(tree(count).content, '|') && ~strcmp(tree(count).content, '~') 
            tree(count).content = convertAtomPred(tree(count).content);
        end
        braccount = 0;
        correctexp = [];
        for i = 1:length(tree(count).content)
            if tree(count).content(i) == '('
                braccount = braccount + 1;
                correctexp = [correctexp, tree(count).content(i)];
            elseif tree(count).content(i) == ')' && braccount ~= 0
                braccount = braccount - 1;
                correctexp = [correctexp, tree(count).content(i)];
            elseif tree(count).content(i) ~= ')'
                correctexp = [correctexp, tree(count).content(i)];
            end
        end
        if braccount ~= 0
            for i = 1:braccount
                correctexp = [correctexp, ')'];
            end
        end
        
        tree(count).content = correctexp;
        count = count - 1;
    end
end


% cleanup--needs to account for assymetric brackets. 

%{
count = length(tree);
bracstack = [];
while ~any(contains(tree(count).content, mainOperators))
    for i = 1:length(tree(count).content)
        if tree(count).content(i) == '('
            bracstack = [bracstack, '('];
        elseif tree(count).content(i) == ')'
            if ~isempty(bracstack) && bracstack(end) == '('
                bracstack(end) = [];
            else
                tree(count).content(i) = '';
            end
          
        end
    end
    tree(count).content(ismember(tree(count).content, '(')) = '';   
    count = count - 1;
    bracstack = [];
end
for i = 1:length(tree)
    disp(tree(i).content)
end
%}


% Stack to store intermediate expressions
stack = {};

for i = 1:length(tree)
    content = tree(length(tree) + 1 - i).content;
    
    % Handle different cases and apply the changes to the expressions
    if strcmp(content, '&&') || strcmp(content, '&')
        
        rightExpr = stack{end};
        leftExpr = stack{end - 1};
        stack = stack(1:end-2);
        newExpr = "min("+ leftExpr+ ","+rightExpr+ ")";
        stack = [stack, newExpr];
    elseif strcmp(content, '||') || strcmp(content, '|')
        
        rightExpr = stack{end};
        leftExpr = stack{end - 1};
        stack = stack(1:end-2);
        newExpr = "max("+ leftExpr+ ","+ rightExpr +")";
        stack = [stack, newExpr];
    elseif strcmp(content, '~')
        
        expr = stack{end};
        stack = stack(1:end-1);
        newExpr = "-"+ expr;
        stack = [stack, newExpr];
    else
        stack = [stack, content];
    end
end

% Check if there is only one final expression in the stack


% The final reconstructed expression will be at the top of the stack
reconstructedExpression = strcat(stack);
newexp = reconstructedExpression;
end