function analyzeResults(tool,model_id)

if ~any(strcmp(tool,["Hecate","STaliro"]))
    error("Incorrect tool name. Use either 'Hecate' or 'STaliro'.")
end

folder = "TestResults";
fileName = tool + "_" + model_id + "_";
fileList = dir(folder);
idx = find(contains({fileList.name},fileName));

if isempty(idx)
    error("No result file is matching the tool and model specified.")
elseif length(idx) > 1
    error("There is more than one file matching the tool and model specified. Remove or rename the old files.")
else
    warning off MATLAB:load:variableNotFound
    results = load(folder + filesep + fileList(idx).name,"succRate","avgIter","medIter","avgTime","medTime");
    warning on MATLAB:load:variableNotFound
    if length(fieldnames(results)) < 3
        results = load(folder + filesep + fileList(idx).name,"Results");

        rob = zeros(1,50);
        iter = zeros(1,50);
        time = zeros(1,50);
        for ii = 1:50
            rob(ii) = results.Results(ii).run.bestRob;
            iter(ii) = results.Results(ii).run.nTests;
            time(ii) = results.Results(ii).run.time;
        end
        fals = (rob <= 0);

        results.succRate = sum(fals)/50;
        results.avgIter = mean(iter(fals));
        results.medIter = median(iter(fals));
        results.avgTime = mean(time(fals));
        results.medTime = median(time(fals));
    end
end

fprintf("Model:\t%s\n",model_id)
fprintf("Tool:\t%s\n",tool)
fprintf("Success Rate:\t%.1f %%\n",results.succRate*100)
fprintf("Avg Iter:\t%.1f\n",results.avgIter)
fprintf("Med Iter:\t%.1f\n",results.medIter)
fprintf("Avg Time:\t%.1f\n",results.avgTime)
fprintf("Med Time:\t%.1f\n",results.medTime)

end