% BooleanExpressionTreeNode.m

classdef BooleanExpressionTreeNode
    properties
        Content
        Parent
        Children
    end
    
    methods
        function node = BooleanExpressionTreeNode(content)
            if nargin > 0
                node.Content = content;
                node.Children = {};
            end
        end
        
        function addChild(node, childNode)
            node.Children{end+1} = childNode;
            childNode.Parent = node;
        end
        
        function isLeaf = isLeafNode(node)
            mainOperators = {'&&', '&', '||', '|', '~'};
            isLeaf = isempty(intersect(mainOperators, strsplit(node.Content)));
        end
        
        function node = buildExpressionTree(node, expression)
            expression = strtrim(expression);
            
            % If the expression is wrapped in parentheses, remove the outermost layer
            if expression(1) == '(' && expression(end) == ')'
                expression = expression(2:end-1);
            end
            
            % Find the main operator (AND, OR) in the expression
            [mainOperator, operatorIndex] = node.findMainOperator(expression);
            
            if ~isempty(mainOperator)
                % Split the expression into left and right sub-expressions
                leftExpression = expression(1:operatorIndex-1);
                rightExpression = expression(operatorIndex+length(mainOperator):end);
                
                % Create a node for the main operator
                node.Content = mainOperator;
                
                % Recursively build left and right sub-trees
                node.addChild(BooleanExpressionTreeNode(leftExpression));
                node.addChild(BooleanExpressionTreeNode(rightExpression));
            else
                % If no main operator found, the expression might be just a single term (e.g., "a")
                node.Content = expression;
            end
        end
        
        function [mainOperator, operatorIndex] = findMainOperator(~, expression)
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
    end
end
