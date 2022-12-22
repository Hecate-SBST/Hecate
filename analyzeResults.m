function analyzeResults(tool,model_id)

if ~any(strcmp(tool,{'Hecate','S-Taliro'}))
    error('Incorrect tool name. Use either ''Hecate'' or ''S-Taliro''.')
end

folder = 'TestResults';
fileName = [tool,'_',model_id,'_'];
fileList = dir(folder);
idx = find(contains({fileList.name},fileName));

if isempty(idx)
    error('No result file is matching the tool and model specified.')
elseif length(idx) > 1
    error('There is more than one file matching the tool and model specified. Remove or rename the old files.')
else
    load([folder,filesep,fileList(idx).name])
end

fprintf('Model:\t%s\n',model_id)
fprintf('Tool:\t%s\n',tool)
fprintf('Success Rate:\t%.1f %%\n',succRate*100)
fprintf('Avg Iter:\t%.1f\n',avgIter)
fprintf('Med Iter:\t%.1f\n',medIter)

end