% This script analyzes the results of Test Translation script.

clear all
close all
clc

%% Find results file

% Find the file names that contains the Test Translation results
fileList = dir('TestResults/');
transCheckList = {};
modelList = {};

for ii = 1:length(fileList)
    if contains(fileList(ii).name,'TranslationCheck_')
        transCheckList = [transCheckList, {fileList(ii).name}];
        name_temp = erase(fileList(ii).name,'TranslationCheck_');
        idx_temp = strfind(name_temp,'_');
        modelList = [modelList, {name_temp(1:idx_temp-1)}];
    end
end

% Check that each model has a single Test Translation results file
if length(modelList) > length(unique(modelList))
    warning('There is more than one file containing translation results for the same benchmark.')
end

%% Analyze results

counter = 0;
results = cell(size(transCheckList));
resultsSummary = table('Size',[size(transCheckList,1),8],...
    'VariableTypes',{'char','char','double','double','double','double','double','double'},...
    'VariableNames',{'Model','Req','nTests','fals_STaliro','diff_STaliro-TA','fals_TA','diff_TA-SF','fals_SF'});

for ii = 1:length(results)
    testResults = load(['TestResults/',transCheckList{ii}],'assessmentData');
    testResults = testResults.assessmentData;
    falsified = false(size(testResults,1),3);

    % S-Taliro result
    fals_STaliro = testResults.("Staliro Robustness") < 0;

    % Test Assessment result
    fals_TA = strcmp(testResults.("Assessment Result"),'Fail');

    % StateFlow result
    fals_SF = testResults.("Stateflow Fitness") < 0;

    % Save results
    results(ii) = {[fals_STaliro, fals_TA, fals_SF]};

    % Display results of each tool
    fprintf('Model: %s\n\n',modelList{ii})
    fprintf('S-Taliro has found %.1f %% failures.\n',sum(fals_STaliro)/length(fals_STaliro)*100);
    fprintf('Test Assessment has found %.1f %% failures.\n',sum(fals_TA)/length(fals_TA)*100);
    fprintf('Stateflow has found %.1f %% failures.\n',sum(fals_SF)/length(fals_SF)*100);

    % Display results of comparison
    comp_STaliro_TA = (fals_STaliro == fals_TA);
    fprintf('S-Taliro and Test Assessment results do not match in %i instances out of %i.\n',sum(~comp_STaliro_TA),length(comp_STaliro_TA));
    
    comp_TA_SF = (fals_TA == fals_SF);
    fprintf('Test Assessment and Stateflow results do not match in %i instances out of %i.\n',sum(~comp_TA_SF),length(comp_TA_SF));

    if ii < length(results)
        fprintf('\n\t*\t*\t*\n\n')
    end
    
    counter = counter + length(comp_STaliro_TA);

    % Save summarized results
    resultsSummary(ii,:) = {modelList{ii},testResults.("Requirement")(1),size(testResults,1),sum(fals_STaliro),sum(~comp_STaliro_TA),sum(fals_TA),sum(~comp_TA_SF),sum(fals_SF)};

end