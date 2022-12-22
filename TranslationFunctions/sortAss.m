function AsInfo_sorted = sortAss(AsInfo_unsorted,AsInfo_sorted_old,stepName,activeScenario)
% This function sorts recursively the table containing all the steps of the
% Test Assessment or Test Sequence block.
%
%           AsInfo_sorted = sortAss(AsInfo_unsorted,AsInfo_sorted_old,stepName,activeScenario);
%
%   E.g.:   AsInfo_sorted = sortAss(AsInfo_unsorted,AsInfo_sorted_old,'Scenario_1.step_1','Scenario_1');
%
% When this function is called by the user, the syntax should be:
%   AssessmentTable = sortAss(AssessmentTable,[],[],activeScenario);
%
% Input:
%   AsInfo_unsorted: Table containing all the steps that have yet to be
%   sorted.
%
%   AsInfo_sorted_old: Table containing all the steps that have been sorted
%   up to this point.
%
%   stepName: char array containing the name of the next step in the sorted
%   table.
%
%   activeScenario: char array containing the name of the active scenario
%   of the block from which the stepTable has been extracted. If the block
%   does not use Scenarios, the variable should be an empty char array ''.
%
% Output:
%   AsInfo_sorted: Table containing all the steps sorted by index and
%   hierarchical level.

    % Save the current step
    if isempty(AsInfo_sorted_old) && ~isempty(AsInfo_unsorted)  % First iteration
        idx = find(AsInfo_unsorted.Index == 1 & AsInfo_unsorted.Hierarchy == 1);
        if length(idx) ~= 1
            error('The sorting algorithm is unable to find the first step in the sequence')
        end
        AsInfo_sorted = AsInfo_unsorted(idx,:);
        stepName = AsInfo_sorted.Name{1};
        
    elseif ~isempty(AsInfo_unsorted)                            % Following iterations
        idx = find(strcmp(AsInfo_unsorted.Name,stepName));
        if length(idx) > 1
            warning('There are multiple steps with the same name. Remove non unique steps before using the step sorting function.')
        end
        AsInfo_sorted = [AsInfo_sorted_old; AsInfo_unsorted(idx,:)];

    end

    % Remove the chosen step from list
    AsInfo_unsorted(idx,:) = [];

    % Search for the next step in the sequence
    if isempty(AsInfo_unsorted) % Last iteration
        disp('Finished sorting')

    else                        % Intermediary iterations
        
        % Get the name of the parent step
        temp_str = strsplit(stepName,'.');
        stepRoot = char(join(temp_str(1:end-1),'.'));

        % Search for first sub-step
        if any(contains(AsInfo_unsorted.Name,stepName) & AsInfo_unsorted.Hierarchy > AsInfo_sorted.Hierarchy(end))

            bool_sub = contains(AsInfo_unsorted.Name,stepName) & AsInfo_unsorted.Index == 1 & AsInfo_unsorted.Hierarchy == (AsInfo_sorted.Hierarchy(end)+1);
            if sum(bool_sub) > 1
                error('There are multiple substeps with the same name. Remove non unique steps before using the step sorting function.')
            elseif ~any(bool_sub)
                error('One substep is missing from the set. Check that all the steps have been read from the block.')
            end
            AsInfo_sorted = sortAss(AsInfo_unsorted,AsInfo_sorted,AsInfo_unsorted.Name{bool_sub},activeScenario);

        % Search for the following step
        elseif any(contains(AsInfo_unsorted.Name,stepRoot))

            bool_next = contains(AsInfo_unsorted.Name,stepRoot) & AsInfo_unsorted.Index == (AsInfo_sorted.Index(end)+1) & AsInfo_unsorted.Hierarchy == AsInfo_sorted.Hierarchy(end);
            if sum(bool_next) > 1
                error('There are multiple next steps with the same name. Remove non unique steps before using the step sorting function.')
            elseif ~any(bool_next)
                error('One next step is missing from the set. Check that all the steps have been read from the block.')
            end
            AsInfo_sorted = sortAss(AsInfo_unsorted,AsInfo_sorted,AsInfo_unsorted.Name{bool_next},activeScenario);

        % Search for the following step of a parent step
        else
            % If there is no parent step, but the unsorted array is still
            % full, then an error occured
            if isempty(stepRoot) || strcmp(stepRoot,activeScenario)
                error('The sorting algorithm missed a step. Check that all the steps have been read from the block.')
            end
            
            bool_par = false;
            while ~any(bool_par)
                % Get the parent step
                ParStep = AsInfo_sorted(strcmp(AsInfo_sorted.Name,stepRoot),:);
    
                % Get the name of the parent of the parent step
                temp_str = strsplit(stepRoot,'.');
                stepRootRoot = char(join(temp_str(1:end-1),'.'));
                
                bool_par = contains(AsInfo_unsorted.Name,stepRootRoot) & AsInfo_unsorted.Index == (ParStep.Index+1) & AsInfo_unsorted.Hierarchy == ParStep.Hierarchy;
                if sum(bool_par) > 1
                    error('There are multiple next steps of the parent step with the same name. Remove non unique steps before using the step sorting function.')
                end
                stepRoot = stepRootRoot;
            end
            AsInfo_sorted = sortAss(AsInfo_unsorted,AsInfo_sorted,AsInfo_unsorted.Name{bool_par},activeScenario);

        end

    end

end