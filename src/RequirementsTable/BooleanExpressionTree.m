% BooleanExpressionTree.m

classdef BooleanExpressionTree
    properties
        Root
    end
    
    methods
        function tree = BooleanExpressionTree()
            tree.Root = BooleanExpressionTreeNode();
        end
        
        function addExpression(tree, expression)
            tree.Root = tree.Root.buildExpressionTree(expression);
        end
        
        function print(tree)
            tree.printRecursive(tree.Root, 0);
        end
    end
    
    methods (Access = private)
        function printRecursive(~, node, depth)
            if ~isempty(node)
                % Indentation based on depth
                fprintf('%s%s\n', repmat('  ', 1, depth), node.Content);
                
                % Recursive call for children
                for i = 1:length(node.Children)
                    tree.printRecursive(node.Children{i}, depth+1);
                end
            end
        end
    end
end


function [mainOperator, operatorIndex] = findMainOperator(expression)
    mainOperators = {'&&', '&', '||', '|', '~'};
    mainOperator = '';
    operatorIndex = 0;
    
    openParen = 0;
    closeParen = 0;
    isInQuotes = false;
    
    for i = 1:length(expression)
        if expression(i) == '(' && ~isInQuotes
            openParen = openParen + 1;
        elseif expression(i) == ')' && ~isInQuotes
            closeParen = closeParen + 1;
        elseif expression(i) == ''''
            isInQuotes = ~isInQuotes;
        end
        
        if openParen == closeParen
            for j = 1:length(mainOperators)
                operator = mainOperators{j};
                operatorLength = length(operator);
                
                for k = 1:length(expression) - operatorLength + 1
                    if expression(k:k + operatorLength - 1) == operator
                        mainOperator = operator;
                        operatorIndex = k;
                        return;
                    end
                end
            end
        end
    end
end
