function checkScenario(activeScenario,blockPath)
% This function checks if the variable activeScenario has the correct
% format and activate the corresponding scenario for the Test Assessment or
% Test Sequence block.
%
%           checkScenario(activeScenario,blockPath)
%
%   E.g.:   checkScenario('Scenario_1','vdp/Test Sequence')
%
% Input:
%   activeScenario: char array containing the name of the active Scenario.
%   If the block doesn't use scenarios, then this variable should be an
%   empty char array: activeScenario = '';
%
%   blockPath: char array containing the path to the block.

% Check whether the current block supports Scenarios
bool_useScenario = sltest.testsequence.isUsingScenarios(blockPath);

if ~isempty(activeScenario)
    if ~bool_useScenario
        error('The block %s does not enable scenarios, set the corresponding activeScenario to empty char array.', blockPath);
    else
        % Check if the chosen scenario is among the available ones
        ScenList = sltest.testsequence.getAllScenarios(blockPath); % List of available scenarios
        if any(strcmp(ScenList,activeScenario))
            if ~strcmp(activeScenario,sltest.testsequence.getActiveScenario(blockPath))
                % Check if it is possible to change the current scenario
                try
                    sltest.testsequence.activateScenario(blockPath,activeScenario);
                catch
                    error('It is not possible to change the active scenario when the UI window of the block %s is open. Close it and retry.', blockPath)
                end
            end
        else
            ErrMsg = sprintf('The chosen scenario for block %s is not among the available ones. Please choose one from the following:\n',blockPath);
            for ii = 1:length(ScenList)
                AddMsg = sprintf('\t%s\n',ScenList{ii});
                ErrMsg = [ErrMsg, AddMsg];
            end
            error(ErrMsg)
        end
    end
    fprintf('Extracting information from Scenario: %s\n',activeScenario)

else
    if bool_useScenario
        ScenList = sltest.testsequence.getAllScenarios(blockPath);
        ErrMsg = sprintf('activeScenario is empty, but the block %s uses scenarios. Please choose one from the following:\n',blockPath);
        for ii = 1:length(ScenList)
            AddMsg = sprintf('\t%s\n',ScenList{ii});
            ErrMsg = [ErrMsg, AddMsg];
        end
        error(ErrMsg)
    end
end

end