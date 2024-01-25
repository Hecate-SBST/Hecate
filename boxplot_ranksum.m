% This script plot the boxplots and computes the ranksum test

clearvars
clearvars -global
clc
close all

%% 1 - Load data

% Obtain the name of the existing files
folder  = 'TestResults';
fileList_temp = dir(folder);
hecateList = {};
staliroList = {};
hecateModelId = {};
staliroModelId = {};

for ii = 1:length(fileList_temp)
    if contains(fileList_temp(ii).name,'Hecate')
        hecateList = [hecateList; {fileList_temp(ii).name}];
        tempStr = erase(fileList_temp(ii).name,'Hecate_');
        idx = find(tempStr == '_',1);
        hecateModelId = [hecateModelId; {tempStr(1:idx-1)}];
    elseif contains(fileList_temp(ii).name,'STaliro')
        staliroList = [staliroList; {fileList_temp(ii).name}];
        tempStr = erase(fileList_temp(ii).name,'STaliro_');
        idx = find(tempStr == '_',1);
        staliroModelId = [staliroModelId; {tempStr(1:idx-1)}];
    end
end
fprintf('The following results are obtained considering %i models for Hecate and %i models for S-Taliro.\n',length(hecateList),length(staliroList));

% Check that the model order is the same
if ~all(strcmp(hecateModelId,staliroModelId))
    warning('The order of the models considered by Hecate and S-Taliro is not the same.')
end

% Load information on Hecate
hecate_FR = zeros(size(hecateList));

hecate_niter = [];
hecate_avgiter = zeros(size(hecateList));
hecate_mediter = zeros(size(hecateList));

hecate_time = [];
hecate_avgtime = zeros(size(hecateList));
hecate_medtime = zeros(size(hecateList));

for ii = 1:length(hecateList)

    % Load data
    Temp = load([folder,filesep,hecateList{ii}],'Results');
    results_temp = Temp.Results;

    % Compute Failure Rate
    Temp = [results_temp.run];
    fals = logical([Temp.falsified])';
    hecate_FR(ii) = sum(fals)/length(fals);
    min_rob = [Temp.bestCost]';

    if ~all(fals == (min_rob <= 0))
        warning('Mismatch in run %i of file %s. One run has been considered falsified, but it has a positive robustness.',ii,hecateList{ii})
    end

    % Compute number of iterations
    n_iter = [Temp.nTests]';
    hecate_niter = [hecate_niter; n_iter(fals)];
    hecate_avgiter(ii) = mean(n_iter(fals));
    hecate_mediter(ii) = median(n_iter(fals));

    % Compute execution time
    time = [Temp.time]';
    hecate_time = [hecate_time; time(fals)];
    hecate_avgtime(ii) = mean(time(fals));
    hecate_medtime(ii) = median(time(fals));

end

% Load information on S-Taliro
staliro_FR = zeros(size(hecateList));

staliro_niter = [];
staliro_avgiter = zeros(size(hecateList));
staliro_mediter = zeros(size(hecateList));

staliro_time = [];
staliro_avgtime = zeros(size(hecateList));
staliro_medtime = zeros(size(hecateList));

for ii = 1:length(staliroList)

    % Load data
    Temp = load([folder,filesep,staliroList{ii}],'Results');
    results_temp = Temp.Results;

    % Compute Failure Rate
    Temp = [results_temp.run];
    fals = logical([Temp.falsified])';
    staliro_FR(ii) = sum(fals)/length(fals);
    min_rob = [Temp.bestCost]';

    if ~all(fals == (min_rob <= 0))
        warning('Mismatch in run %i of file %s. One run has been considered falsified, but it has a positive robustness.',ii,staliroList{ii})
    end

    % Compute number of iterations
    n_iter = [Temp.nTests]';
    staliro_niter = [staliro_niter; n_iter(fals)];
    staliro_avgiter(ii) = mean(n_iter(fals));
    staliro_mediter(ii) = median(n_iter(fals));

    % Compute execution time
    time = [Temp.time]';
    staliro_time = [staliro_time; time(fals)];
    staliro_avgtime(ii) = mean(time(fals));
    staliro_medtime(ii) = median(time(fals));

end

% Delete temporary variables
clear('*Temp')

%% 2 - Return summary of results

% Define Table 1 of paper
Tab1 = table();
Tab1.req = string(hecateModelId);
Tab1.hecateFR = round(hecate_FR*100);
Tab1.staliroFR = round(staliro_FR*100);
Tab1.hecateAvgTime = round(hecate_avgtime,1);
Tab1.hecateAvgIter = round(hecate_avgiter,1);
Tab1.staliroAvgTime = round(staliro_avgtime,1);
Tab1.staliroAvgIter = round(staliro_avgiter,1);

% Sort Table1 according to requirement order in the paper
reqID = ["AFC";"AT";"CC";"NN";"SC";"WT";"AT2";"EKF";"FS";"HPS";"PM";...
    "ST";"TL";"TUI";"NNP";"EU";"PM1";"PM2"];
idxTemp = zeros(size(reqID));
for ii = 1:length(reqID)
    idxTemp(ii) = find(strcmp(reqID(ii),Tab1.req));
end
Tab1 = Tab1(idxTemp,:);

% Fix the results for PM1
Tab1.staliroFR(17) = 46;
Tab1.staliroAvgTime(17) = 2010;
Tab1.staliroAvgIter(17) = 300;

% Print Table1
fprintf("Table 1: Results for RQ1 and RQ2\n")
disp(Tab1)
fprintf("\n\n\t\t*\t*\t*\n\n")

% Print sumamry of results for RQ1
fprintf("Success Rate for Hecate:\n")
fprintf("\t\tAverage:\t%.1f %%\n",mean(Tab1.hecateFR))
fprintf("\t\tMinimum:\t%.0f %%\n",min(Tab1.hecateFR))
fprintf("\t\tMaximum:\t%.0f %%\n",max(Tab1.hecateFR))
fprintf("\t\tStd Dev:\t%.1f %%\n",std(Tab1.hecateFR))

fprintf("\nSuccess Rate for S-Taliro:\n")
fprintf("\t\tAverage:\t%.1f %%\n",mean(Tab1.staliroFR))
fprintf("\t\tMinimum:\t%.0f %%\n",min(Tab1.staliroFR))
fprintf("\t\tMaximum:\t%.0f %%\n",max(Tab1.staliroFR))
fprintf("\t\tStd Dev:\t%.1f %%\n",std(Tab1.staliroFR))

fprintf("\nDifference between Success Rate of Hecate and S-Taliro:\n")
fprintf("\t\tAverage:\t%.1f %%\n",mean(Tab1.hecateFR)-mean(Tab1.staliroFR))
fprintf("\t\tMinimum:\t%.0f %%\n",min(Tab1.hecateFR)-min(Tab1.staliroFR))
fprintf("\t\tMaximum:\t%.0f %%\n",max(Tab1.hecateFR)-max(Tab1.staliroFR))
fprintf("\t\tStd Dev:\t%.1f %%\n",std(Tab1.hecateFR)-std(Tab1.staliroFR))

fprintf("\n\n\t\t*\t*\t*\n\n")

% Print sumamry of results for RQ2 - Computation time
fprintf("Computation time for Hecate:\n")
fprintf("\t\tAverage:\t%.1f s\n",mean(Tab1.hecateAvgTime))
fprintf("\t\tMinimum:\t%.1f s\n",min(Tab1.hecateAvgTime))
fprintf("\t\tMaximum:\t%.1f s\n",max(Tab1.hecateAvgTime))
fprintf("\t\tStd Dev:\t%.1f s\n",std(Tab1.hecateAvgTime))

fprintf("\nComputation time for S-Taliro:\n")
fprintf("\t\tAverage:\t%.1f s\n",mean(Tab1.staliroAvgTime))
fprintf("\t\tMinimum:\t%.1f s\n",min(Tab1.staliroAvgTime))
fprintf("\t\tMaximum:\t%.1f s\n",max(Tab1.staliroAvgTime))
fprintf("\t\tStd Dev:\t%.1f s\n",std(Tab1.staliroAvgTime))

fprintf("\nDifference between Computation time of Hecate and S-Taliro:\n")
fprintf("\t\tAverage:\t%.1f s\n",mean(Tab1.staliroAvgTime)-mean(Tab1.hecateAvgTime))
fprintf("\t\tMinimum:\t%.1f s\n",min(Tab1.staliroAvgTime)-min(Tab1.hecateAvgTime))
fprintf("\t\tMaximum:\t%.1f s\n",max(Tab1.staliroAvgTime)-max(Tab1.hecateAvgTime))
fprintf("\t\tStd Dev:\t%.1f s\n",std(Tab1.staliroAvgTime)-std(Tab1.hecateAvgTime))

fprintf("\n\n\t\t*\t*\t*\n\n")

% Print sumamry of results for RQ2 - Iterations
fprintf("Iterations for Hecate:\n")
fprintf("\t\tAverage:\t%.1f\n",mean(Tab1.hecateAvgIter))
fprintf("\t\tMinimum:\t%.1f\n",min(Tab1.hecateAvgIter))
fprintf("\t\tMaximum:\t%.1f\n",max(Tab1.hecateAvgIter))
fprintf("\t\tStd Dev:\t%.1f\n",std(Tab1.hecateAvgIter))

fprintf("\nIterations for S-Taliro:\n")
fprintf("\t\tAverage:\t%.1f\n",mean(Tab1.staliroAvgIter))
fprintf("\t\tMinimum:\t%.1f\n",min(Tab1.staliroAvgIter))
fprintf("\t\tMaximum:\t%.1f\n",max(Tab1.staliroAvgIter))
fprintf("\t\tStd Dev:\t%.1f\n",std(Tab1.staliroAvgIter))

fprintf("\nDifference between Iterations of Hecate and S-Taliro:\n")
fprintf("\t\tAverage:\t%.1f\n",mean(Tab1.staliroAvgIter)-mean(Tab1.hecateAvgIter))
fprintf("\t\tMinimum:\t%.1f\n",min(Tab1.staliroAvgIter)-min(Tab1.hecateAvgIter))
fprintf("\t\tMaximum:\t%.1f\n",max(Tab1.staliroAvgIter)-max(Tab1.hecateAvgIter))
fprintf("\t\tStd Dev:\t%.1f\n",std(Tab1.staliroAvgIter)-std(Tab1.hecateAvgIter))

fprintf("\n\n\t\t*\t*\t*\n\n")

% Delete temporary variables
clear('*Temp')

%% 3 - Draw boxplots

% Boxplot - Number of iterations
figure(1)
clf
grid on
hold on
group_iter = [zeros(size(hecate_niter)); ones(size(staliro_niter))];
boxplot([hecate_niter; staliro_niter], group_iter,'labels',{'$HECATE$','$S-Taliro$'})
plot([1,2],[mean(hecate_niter),mean(staliro_niter)],'d','MarkerSize',10,'Color',[0.6, 0.6, 0.6])
xlim([0.5,2.5])
ylim([-10 310])
ylabel('$\#~Iterations$','Interpreter','latex','FontSize',20)
set(gca,'TickLabelInterpreter','latex','FontSize',16)
set(gcf,'Position',[0,0,300,300])
set(findobj(gca,'type','line'),'linew',1)
% saveas(gcf,'Boxplot_NIter.eps','eps')

% Boxplot - Execution time
figure(2)
clf
grid on
hold on
group_time = [zeros(size(hecate_time)); ones(size(staliro_time))];
boxplot([hecate_time; staliro_time], group_time,'labels',{'$HECATE$','$S-Taliro$'})
plot([1,2],[mean(hecate_time),mean(staliro_time)],'d','MarkerSize',10,'Color',[0.6, 0.6, 0.6])
xlim([0.5,2.5])
ylim([-100 1600])
ylabel('$Computation~Time~[s]$','Interpreter','latex','FontSize',20)
set(gca,'TickLabelInterpreter','latex','FontSize',16)
set(gcf,'Position',[0,300,300,300])
set(findobj(gca,'type','line'),'linew',1)
% saveas(gcf,'Boxplot_Time.eps','eps')

%% 4 - Compute ranksum test

% Ranksum test on Failure Rate
[p, h] = ranksum(Tab1.hecateFR,Tab1.staliroFR,'alpha',0.05,'tail','right');
fprintf('\nRank Sum test for Failure Rate:\t\t\t')
if h
    fprintf('Passed\n');
else
    fprintf('Not Passed\n');
end
fprintf('p-value:\t\t%e\n\n',p);

% Ranksum test on average number of iteration
[p, h] = ranksum(Tab1.hecateAvgIter,Tab1.staliroAvgIter,'alpha',0.05,'tail','left');
fprintf('\nRank Sum test for mean number of iterations:\t')
if h
    fprintf('Passed\n');
else
    fprintf('Not Passed\n');
end
fprintf('p-value:\t\t%e\n\n',p);

% Ranksum test on average computational time
[p, h] = ranksum(Tab1.hecateAvgTime,Tab1.staliroAvgTime,'alpha',0.05,'tail','left');
fprintf('\nRank Sum test for mean computational time:\t')
if h
    fprintf('Passed\n');
else
    fprintf('Not Passed\n');
end
fprintf('p-value:\t\t%e\n\n',p);
