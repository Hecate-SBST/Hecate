%% Find the result files
clear all
clc

folder = 'Results';
tool = 'Hecate';       % Either 'Hecate' or 'STaliro'
model_id = 'CC';

fileList = dir(folder);
resultList = {};

for ii = 1:length(fileList)
    if contains(fileList(ii).name,[tool,'_',model_id])
        resultList = [resultList; {[folder,filesep,fileList(ii).name]}];
    end
end

if isempty(resultList)
    error('No result file exist for the tool %s and the model %s in the folder %s.',tool, model_id, folder)
end

if length(resultList) ~= 5
    warning('The script expeced to find 5 result files (10 runs per each). Instead, it is considering %i files.',length(resultList))
end

%% Load and join the files

load(resultList{1})

Results = [];
History = [];
Options = [];

for ii = 1:length(resultList)

    temp = load(resultList{ii},'Results','History','Options');

    if length(temp.Results) < 10
        warning('The file %s contains less than 10 runs. N_runs = %i.',resultList{ii},length(temp.Results))
    end

    Results = [Results; temp.Results];
    History = [History; temp.History];
    Options = [Options; temp.Options];

end

%% Analyze results

% Falsified?
temp = [Results.run];
fals = logical([temp.falsified])';

% Number of iterations
n_iter = [temp.nTests]';

% Quality parameters
succRate = sum(fals)/length(fals);
avgIter = mean(n_iter(fals));
medIter = median(n_iter(fals));

fprintf('Model:\t%s\n',model_id)
fprintf('Tool:\t%s\n',tool)
fprintf('Success Rate:\t%.1f %%\n',succRate*100)
fprintf('Avg Iter:\t%.1f\n',avgIter)
fprintf('Med Iter:\t%.1f\n',medIter)

%% Save joined results

if strcmp(tool,'Hecate') || strcmp(tool,'STaliro')
    date = resultList{1}(length([folder,filesep,tool,'_',model_id,'_'])+1:end);
elseif strcmp(tool,'S-Taliro')
    tool = 'STaliro';
    date = resultList{1}(length([folder,filesep,tool,'_',model_id,'_'])+1:end);
else
    error('Unrecognized tool name.')
end

date = date(1:8);
saveStr = ['TestResults',filesep,tool,'_',model_id,'_',date];
fprintf('\nThe overall results were saved in %s.mat.\n',saveStr)

save(saveStr)
