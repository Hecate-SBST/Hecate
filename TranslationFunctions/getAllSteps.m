function stepTable = getAllSteps(activeScenario, blockPath)
% Get all steps from the provided block path.
%
%           stepTable = getAllSteps(activeScenario, blockPath)
%
%   E.g.:   stepTable = getAllSteps('Scenario_1','vdp/Test Sequence')
%
% Input:
%   activeScenario: char array containing the name of the active scenario
%   in the Test Sequence or Test Assessment block.
%
%   blockPath:char array containing the path to the Test Assessment or Test
%   Sequence block.
%
% Output:
%   stepTable: table containing information for all the existing steps in
%   the active scenario of the active Test Assessment or Test Sequence
%   block. The columns of the table are the following:
%   
%                Name: 'Scenario_3.step_1.step_1_3'
%              Action: 'verify(speed < 130)'
%          IsWhenStep: 0
%       IsWhenSubStep: 1
%       WhenCondition: ''
%         Description: ''
%               Index: 3
%     TransitionCount: 0
%           Hierarchy: 2

stepInfo = []; % Array to hold the information of each step

% Get the name of all the available steps for all the scenarios
stepList = sltest.testsequence.findStep(blockPath);

% Save the information of the steps of the active scenario only
for ii = 1:length(stepList)
    
    tempStr = split(stepList{ii},'.');

    % Read only the steps of the currently active scenario
    if ~isempty(activeScenario) && ~strcmp(tempStr{1},activeScenario)
        continue
    end

    stepProperties = sltest.testsequence.readStep(blockPath,stepList{ii});

    % Evaluate hierarchical value of the step
    hierarchy = count(stepProperties.Name,'.');
    if isempty(activeScenario)
        hierarchy = hierarchy+1;
    end
    stepProperties.Hierarchy = hierarchy;

    % If this step is missing the WhenCondition field, add it
    if ~isfield(stepProperties,'WhenCondition')
        stepProperties.WhenCondition = '';
    end
    
    % Append the step to the list
    stepInfo= [stepInfo; stepProperties];
    
end

% Convert struct to a table
stepTable = struct2table(stepInfo,'AsArray',true);

end