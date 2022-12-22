% This script plot the boxplots and computes the ranksum test

clear all
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
    temp = load([folder,filesep,hecateList{ii}],'Results');
    results_temp = temp.Results;

    % Compute Failure Rate
    temp = [results_temp.run];
    fals = logical([temp.falsified])';
    hecate_FR(ii) = sum(fals)/length(fals);
    min_rob = [temp.bestCost]';

    if ~all(fals == (min_rob <= 0))
        error('Mismatch in file %s. One run has been considered falsified, but it has a positive robustness.')
    end

    % Compute number of iterations
    n_iter = [temp.nTests]';
    hecate_niter = [hecate_niter; n_iter(fals)];
    hecate_avgiter(ii) = mean(n_iter(fals));
    hecate_mediter(ii) = median(n_iter(fals));

    % Compute execution time
    time = [temp.time]';
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
    temp = load([folder,filesep,staliroList{ii}],'Results');
    results_temp = temp.Results;

    % Compute Failure Rate
    temp = [results_temp.run];
    fals = logical([temp.falsified])';
    staliro_FR(ii) = sum(fals)/length(fals);
    min_rob = [temp.bestCost]';

    if ~all(fals == (min_rob <= 0))
        error('Mismatch in file %s. One run has been considered falsified, but it has a positive robustness.')
    end

    % Compute number of iterations
    n_iter = [temp.nTests]';
    staliro_niter = [staliro_niter; n_iter(fals)];
    staliro_avgiter(ii) = mean(n_iter(fals));
    staliro_mediter(ii) = median(n_iter(fals));

    % Compute execution time
    time = [temp.time]';
    staliro_time = [staliro_time; time(fals)];
    staliro_avgtime(ii) = mean(time(fals));
    staliro_medtime(ii) = median(time(fals));

end

%% 2 - Draw boxplots

% Boxplot - Number of iterations
figure(1)
group_iter = [zeros(size(hecate_niter)); ones(size(staliro_niter))];
boxplot([hecate_niter; staliro_niter], group_iter,'labels',{'$HECATE$','$S-Taliro$'})
grid on
hold on
plot([1,2],[mean(hecate_niter),mean(staliro_niter)],'gd','MarkerSize',10)
ylim([-10 310])
ylabel('$\#~Iterations$','Interpreter','latex','FontSize',20)
set(gca,'TickLabelInterpreter','latex','FontSize',16)
set(gcf,'Position',[0,0,300,200])
saveas(gcf,'Boxplot_NIter.eps','eps')

% Boxplot - Execution time
figure(2)
group_time = [zeros(size(hecate_time)); ones(size(staliro_time))];
boxplot([hecate_time; staliro_time], group_time,'labels',{'$HECATE$','$S-Taliro$'})
grid on
hold on
plot([1,2],[mean(hecate_time),mean(staliro_time)],'gd','MarkerSize',10)
ylim([-100 1600])
ylabel('$Computation~Time~[s]$','Interpreter','latex','FontSize',20)
set(gca,'TickLabelInterpreter','latex','FontSize',16)
set(gcf,'Position',[0,300,300,200])
saveas(gcf,'Boxplot_Time.eps','eps')

%% 3 - Compute ranksum test

fprintf('\n\t\t*\t*\t*\n')

% Ranksum test on Failure Rate
[p, h] = ranksum(hecate_FR,staliro_FR,'alpha',0.05,'tail','right');
fprintf('\nRank Sum test for Failure Rate:\t')
if h
    fprintf('Passed\n');
else
    fprintf('Not Passed\n');
end
fprintf('p-value:\t\t%e\n\n',p);

fprintf('\n\t\t*\t*\t*\n')

% Ranksum test on number of iteration
[p, h] = ranksum(hecate_niter,staliro_niter,'alpha',0.05,'tail','left');
fprintf('\nRank Sum test for number of iterations (all together):\t')
if h
    fprintf('Passed\n');
else
    fprintf('Not Passed\n');
end
fprintf('p-value:\t\t%e\n\n',p);

% Ranksum test on average number of iteration
[p, h] = ranksum(hecate_avgiter,staliro_avgiter,'alpha',0.05,'tail','left');
fprintf('\nRank Sum test for mean number of iterations:\t')
if h
    fprintf('Passed\n');
else
    fprintf('Not Passed\n');
end
fprintf('p-value:\t\t%e\n\n',p);

% Ranksum test on median number of iteration
[p, h] = ranksum(hecate_mediter,staliro_mediter,'alpha',0.05,'tail','left');
fprintf('\nRank Sum test for median number of iterations:\t')
if h
    fprintf('Passed\n');
else
    fprintf('Not Passed\n');
end
fprintf('p-value:\t\t%e\n\n',p);

fprintf('\n\t\t*\t*\t*\n')

% Ranksum test on computational time
[p, h] = ranksum(hecate_time,staliro_time,'alpha',0.05,'tail','left');
fprintf('\nRank Sum test for computational time (all together):\t')
if h
    fprintf('Passed\n');
else
    fprintf('Not Passed\n');
end
fprintf('p-value:\t\t%e\n\n',p);

% Ranksum test on average computational time
[p, h] = ranksum(hecate_avgtime,staliro_avgtime,'alpha',0.05,'tail','left');
fprintf('\nRank Sum test for mean computational time:\t')
if h
    fprintf('Passed\n');
else
    fprintf('Not Passed\n');
end
fprintf('p-value:\t\t%e\n\n',p);

% Ranksum test on median computational time
[p, h] = ranksum(hecate_medtime,staliro_medtime,'alpha',0.05,'tail','left');
fprintf('\nRank Sum test for median computational time:\t')
if h
    fprintf('Passed\n');
else
    fprintf('Not Passed\n');
end
fprintf('p-value:\t\t%e\n\n',p);

%% 4 - Table RQ2

RQ2 = table(hecateModelId,hecate_avgtime,hecate_avgiter,staliroModelId,staliro_avgtime,staliro_avgiter);