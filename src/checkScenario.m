function hecateOptions = checkScenario(hecateOptions,blockPath,testSequenceFlag)
% This function checks if the object hecateOptions has information about
% the test scenarios and activate the corresponding scenario for the Test
% Assessment or Test Sequence block.
%
%           checkScenario(hecateOptions,blockPath,testSequenceFlag)
%
%   E.g.:   checkScenario(hecateOptions,"vdp/Test Sequence",true)
%
% Input:
%   hecateOptions: object of type hecate_options. It contains information
%   on the Test Sequence and Test Assessment scenario under analysis.
%
%   blockPath: string containing the path to the block.
%
%   testSequenceFlag: boolean variable specifying if the function is being
%   applied to a Test Sequence or a Test Assessment block.
%
% Outputs:
%   hecateOptions: object of type hecate_options. It contains updated
%   information (if necessary) on the Test Sequence and Test Assessment
%   scenario under analysis.
%
% (C) 2022, Federico Formica, Tony Fan, McMaster University
% (C) 2024, Federico Formica, McMaster University

% Define Test Block scenario
if testSequenceFlag
    activeScenario = hecateOptions.sequence_scenario;
else
    activeScenario = hecateOptions.assessment_scenario;
end

% Check whether the current block supports Scenarios
boolUseScenario = sltest.testsequence.isUsingScenarios(blockPath);

if ~isempty(activeScenario)
    if ~boolUseScenario
        if testSequenceFlag
            hecateOptions.sequence_scenario = "";
        else
            hecateOptions.assessment_scenario = "";
        end
        warning("The block %s does not enable scenarios, set the corresponding activeScenario to empty char array.", blockPath);
    else
        % Check if the chosen scenario is among the available ones
        scenList = sltest.testsequence.getAllScenarios(blockPath); % List of available scenarios
        if any(strcmp(scenList,activeScenario))
            if ~strcmp(activeScenario,sltest.testsequence.getActiveScenario(blockPath))
                % Check if it is possible to change the current scenario
                try
                    sltest.testsequence.activateScenario(blockPath,activeScenario);
                catch
                    error("It is not possible to change the active scenario when the UI window of the block %s is open. Close it and retry.", blockPath)
                end
            end
        else
            ErrMsg = sprintf("The chosen scenario for block %s is not among the available ones. Please choose one from the following:\n",blockPath);
            for ii = 1:length(scenList)
                addMsg = sprintf("\t%s\n",scenList{ii});
                ErrMsg = ErrMsg + addMsg;
            end
            error(ErrMsg)
        end
    end
    fprintf("Extracting information from Scenario: %s\n",activeScenario)

else
    if boolUseScenario
        activeScenario = sltest.testsequence.getActiveScenario(blockPath);
        if testSequenceFlag
            warning("'hecateOptions.sequence_scenario' is empty, but the block %s uses scenarios.\nHecate will use the currently active scenario: %s\n",blockPath,activeScenario)
            hecateOptions.sequence_scenario = activeScenario;
        else
            warning("'hecateOptions.assessment_scenario' is empty, but the block %s uses scenarios.\nHecate will use the currently active scenario: %s\n",blockPath,activeScenario)
            hecateOptions.assessment_scenario = activeScenario;
        end
        fprintf("Extracting information from Scenario: %s\n",activeScenario)
    end
end

end