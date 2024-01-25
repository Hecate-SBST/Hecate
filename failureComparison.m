clearvars
clc

warning on verbose
    
% Turn off warning if verify is falsified
warning off Stateflow:Runtime:TestVerificationFailed

% Turn off warning if the fitness value is Inf
warning off Simulink:Engine:BlockOutputInfNanDetectedError

% Turn off warning for unused symbols in Test Sequence and Test Assessment
warning off Stateflow:reactive:UnusedDataInReactiveTestingTableChart
warning off Stateflow:cdr:UnusedDataOrEvent

% Turn off warning for imposed equality inside verify
warning off Stateflow:cdr:VerifyDangerousComparison

% Turn off warning for rmpath in Directory Not Found
warning off MATLAB:rmpath:DirNotFound

addpath(genpath("staliro"))

%% Find all data files of Hecate and S-Taliro

folder = "TestResults";
fileList = dir(folder);
fileName = string({fileList.name})';

% Remove files that do not start with 'Hecate' or 'STaliro'
boolMask = contains(fileName,["Hecate","STaliro"]);
fileList = fileList(boolMask);
fileName = fileName(boolMask);

% Create table containing file references
fileTable = table('Size',[length(fileList),4],'VariableTypes',{'string','string','string','string'}, ...
    'VariableNames',{'Tool','Requirement','Date','File_name'});

for ii = 1:length(fileName)

    % Drop the format '.mat'
    fileTemp = erase(fileName{ii},'.mat');

    % Split name into single information
    fileInfo = split(fileTemp,'_');

    % Save information in table
    fileTable.Tool(ii) = string(fileInfo(1));
    fileTable.Requirement(ii) = string(fileInfo(2));
    fileTable.Date(ii) = string(join(fileInfo(3:end),"-"));
    fileTable.File_name(ii) = string(fileName(ii));
end

%% Get requirements

% Obtain list of requirement
reqList = unique(fileTable.Requirement);
reqList = sort(reqList);

% Check that there is one and only one file for each requirement (for both
% tools)
for ii = 1:length(reqList)

    % Check for Hecate
    hecateTemp = fileTable(strcmp(fileTable.Tool,"Hecate") & strcmp(fileTable.Requirement,reqList(ii)),:);
    if height(hecateTemp) == 0
        warning("Hecate has no result file for the benchamrk %s.",reqList(ii));
    elseif height(hecateTemp) > 1
        warning("Hecate has two or more result files for the benchamrk %s.",reqList(ii));
    end

    % Check for S-Taliro
    hecateTemp = fileTable(strcmp(fileTable.Tool,"STaliro") & strcmp(fileTable.Requirement,reqList(ii)),:);
    if height(hecateTemp) == 0
        warning("S-Taliro has no result file for the benchamrk %s.",reqList(ii));
    elseif height(hecateTemp) > 1
        warning("S-Taliro has two or more result files for the benchamrk %s.",reqList(ii));
    end
end

% Check that the requirements match the model folders
modelTemp = dir("Models");
modelTemp = modelTemp([modelTemp.isdir]);
modelTemp = modelTemp(~startsWith({modelTemp.name},"."));
modelList = string({modelTemp.name})';
for ii = 1:length(reqList)
    if ~any(strcmp(modelList,reqList(ii)))
        warning("There is no model folder for requirement %s.",reqList(ii));
    end
end

% Delete temporary variables
clear('*Temp')

%% Read results file

% Choose requirement
nSamples = 3;
Req = "AT";
Req = upper(Req);
if ~any(strcmp(Req,reqList))
    error("The requirement %s is not among the available ones.",Req)
end

% Isolate results file for given requirement
fileReqTable = fileTable(strcmp(Req,fileTable.Requirement),:);
fileHecate = fileReqTable(strcmp("Hecate",fileReqTable.Tool),:);
fileStaliro = fileReqTable(strcmp("STaliro",fileReqTable.Tool),:);

% Read Hecate results
ResultsHecate = load("TestResults/" + fileHecate.File_name(1),"Results","simulationTime","modelname");

% Read STaliro results
ResultsStaliro = load("TestResults/" + fileStaliro.File_name(1),"Results","simulationTime","staliro_InputBounds","staliro_cp_array","staliro_opt","modelname");

% Delete temporary variables
clear('*Temp')

%% Generate Hecate results

% Create empty variable for input-output signals
signalsHecate = struct("t",[],"x",[],"y",[]);
counter = 1;
maxIter = 300;

% Load model
addpath(genpath("Models/" + Req))
modelName = ResultsHecate.modelname;
load_system(modelName);

% Run setting file in base workspace
evalin("base","Setting"+Req)

% Set the manual switches in the model to UP
switchOpt = Simulink.FindOptions('SearchDepth',1);
switchList = Simulink.findBlocksOfType(modelName,'ManualSwitch',switchOpt);
for jj = 1:length(switchList)
    set_param(switchList(jj),'sw','1')
end

% Change time and output name
outputSettings(modelName);

% Loop over runs
for ii = 1:length(ResultsHecate.Results)

    % Skip runs that did not falsify the requirements
    if ((ResultsHecate.Results(ii).run.falsified) ~= (ResultsHecate.Results(ii).run.bestRob <= 0)) || ...
            ((ResultsHecate.Results(ii).run.bestRob <= 0) ~= (ResultsHecate.Results(ii).run.nTests < maxIter))
        warning("Run %i of Hecate for benchmark %s has inconsistent robustness, falsification and number of iterations.",ii,Req)
    end

    if ~ResultsHecate.Results(ii).run.falsified
        continue
    end
    fprintf("Hecate test case: %i/%i\n",counter,nSamples)

    % Generate Hecate variables
    for jj = 1:length(ResultsHecate.Results(ii).HecateParam)
        assignin("base",ResultsHecate.Results(ii).HecateParam{jj},ResultsHecate.Results(ii).run.bestSample(jj));
    end

    % Simulate model
    output = sim(modelName,[0, ResultsHecate.simulationTime]);
    tOut = output.tOut;
    yOut = output.yOut(:,1:end-1);

    % Generate input signals
    xIn = generateInputs(Req,tOut,ResultsHecate.Results(ii).HecateParam,ResultsHecate.Results(ii).run.bestSample);

    % Save input and output signals
    signalsHecate(counter).t = tOut;
    signalsHecate(counter).x = xIn;
    signalsHecate(counter).y = yOut;
    counter = counter+1;

    % Stop after gathering enough samples
    if counter > nSamples
        break
    end

    % Clear Hecate variables
    clear('Hecate_*')
end

% Delete temporary variables
clear('*Temp')

%% Generate S-Taliro results

% Create empty variable for input-output signals
signalsStaliro = struct("t",[],"x",[],"y",[]);
counter = 1;

% Set the manual switches in the model to DOWN
for jj = 1:length(switchList)
    set_param(switchList(jj),'sw','0')
end

% Get simulation options
simopt = simget(modelName);

% Generate fake Hecate parameters
for jj = 1:length(ResultsHecate.Results(1).HecateParam)
    assignin("base",ResultsHecate.Results(1).HecateParam{jj},ResultsHecate.Results(1).run.bestSample(jj));
end

% Loop over runs
for ii = 1:length(ResultsStaliro.Results)

    % Skip runs that did not falsify the requirements
    if ((ResultsStaliro.Results(ii).run.falsified) ~= (ResultsStaliro.Results(ii).run.bestRob <= 0)) || ...
            ((ResultsStaliro.Results(ii).run.bestRob <= 0) ~= (ResultsStaliro.Results(ii).run.nTests < maxIter))
        warning("Run %i of S-Taliro for benchmark %s has inconsistent robustness, falsification and number of iterations.",ii,Req)
    end

    if ResultsStaliro.Results(ii).run.bestRob > 0
        continue
    end
    fprintf("S-Taliro test case: %i/%i\n",counter,nSamples)

    % Generate input signals
    tIn = (0:0.01:ResultsStaliro.simulationTime)';
    xIn = ComputeInputSignals(tIn,ResultsStaliro.Results(ii).run.bestSample, ...
        ResultsStaliro.staliro_opt.interpolationtype,cumsum(ResultsStaliro.staliro_cp_array), ...
        ResultsStaliro.staliro_InputBounds,ResultsStaliro.simulationTime,false);

    % Compute output signals
    output = sim(modelName,[0, ResultsStaliro.simulationTime],simopt,[tIn, xIn]);
    tOut = output.tOut;
    yOut = output.yOut(:,1:end-1);

    % Interpolate input timesteps
    xInTemp = zeros(length(tOut),size(xIn,2));
    for jj = 1:size(xIn,2)
        if strcmp(ResultsStaliro.staliro_opt.interpolationtype{jj},'pchip')
            xInTemp(:,jj) = pchip(tIn,xIn(:,jj),tOut);
        else
            xInTemp(:,jj) = interp1(tIn,xIn(:,jj),tOut);
        end
    end
    xIn = xInTemp;

    % Perform additional operations on input signals (model specific)
    if strcmp(Req,"XX")
        % Do something
    end

    % Save input and output signals
    signalsStaliro(counter).t = tOut;
    signalsStaliro(counter).x = xIn;
    signalsStaliro(counter).y = yOut;
    counter = counter+1;

    % Stop after gathering enough samples
    if counter > nSamples
        break
    end

end

% Remove model folder from path
rmpath(genpath("Models/" + Req))

% Clear Hecate variables
clear('Hecate_*')

% Delete temporary variables
clear('*Temp')

%% Generate plots

% Define color arrays
colorHecate = [0, 0, 1; 0.75, 0.85, 1; 0.5, 0.75, 1];
colorSTaliro = [1, 0, 0; 1, 0.5, 0; 1, 0, 0.5];

% Plot inputs
figure(1)
for ii = 1:size(xIn,2)
    subplot(size(xIn,2),1,ii)
    hold on
    grid on
    for jj = 1:length(signalsHecate)
        plot(signalsHecate(jj).t,signalsHecate(jj).x(:,ii),"color",colorHecate(jj,:))
    end

    for jj = 1:length(signalsStaliro)
        plot(signalsStaliro(jj).t,signalsStaliro(jj).x(:,ii),"color",colorSTaliro(jj,:))
    end
end
sgtitle(sprintf("Input signals for model %s",Req),'FontSize',20)

% Plot outputs
figure(2)
for ii = 1:size(yOut,2)
    subplot(size(yOut,2),1,ii)
    hold on
    grid on
    for jj = 1:length(signalsHecate)
        plot(signalsHecate(jj).t,signalsHecate(jj).y(:,ii),"color",colorHecate(jj,:))
    end

    for jj = 1:length(signalsStaliro)
        plot(signalsStaliro(jj).t,signalsStaliro(jj).y(:,ii),"color",colorSTaliro(jj,:))
    end
end
sgtitle(sprintf("Output signals for model %s",Req),'FontSize',20)

% Only for CC
if strcmp(Req,"CC")
    figure(3)
    hold on
    grid on
    for jj = 1:length(signalsHecate)
        plot(signalsHecate(jj).t,signalsHecate(jj).y(:,5)-signalsHecate(jj).y(:,4),"color",colorHecate(jj,:))
    end
    
    for jj = 1:length(signalsStaliro)
        plot(signalsStaliro(jj).t,signalsStaliro(jj).y(:,5)-signalsStaliro(jj).y(:,4),"color",colorSTaliro(jj,:))
    end
    sgtitle("Output signals for model CC",'FontSize',20)

% Only for AT
elseif strcmp(Req,"AT")
    figure(2)
    subplot(3,1,1)
    plot([0,20],[120,120],'k--','LineWidth',2)

% Only for NN
elseif strcmp(Req,"NN")
    figure(2)
    plot([0, 1, 1, 2, 2, 3],[3.2,3.2,2.25,2.25,2.175,2.175],'k--','LineWidth',2)
    plot([1, 2, 2, 3],[1.75,1.75,1.825,1.825],'k--','LineWidth',2)

% Only for SC
elseif strcmp(Req,"SC")
    figure(3)
    hold on
    grid on
    for jj = 1:length(signalsHecate)
        plot(signalsHecate(jj).t,signalsHecate(jj).y(:,4),"color",colorHecate(jj,:))
    end
    
    for jj = 1:length(signalsStaliro)
        plot(signalsStaliro(jj).t,signalsStaliro(jj).y(:,4),"color",colorSTaliro(jj,:))
    end
    plot([30,35],[87,87],'k--','LineWidth',2)
    plot([30,35],[87.5,87.5],'k--','LineWidth',2)
    sgtitle("Pressure signal for model SC",'FontSize',20)

% Only for WT
elseif strcmp(Req,"WT")
    figure(3)
    hold on
    grid on
    for jj = 1:length(signalsHecate)
        plot(signalsHecate(jj).t,signalsHecate(jj).y(:,3),"color",colorHecate(jj,:))
    end
    
    for jj = 1:length(signalsStaliro)
        plot(signalsStaliro(jj).t,signalsStaliro(jj).y(:,3),"color",colorSTaliro(jj,:))
    end
    plot([30,630],[21000,21000],'k--','LineWidth',2)
    plot([30,630],[47500,47500],'k--','LineWidth',2)
    sgtitle("Torque signal for model WT",'FontSize',20)

% Only for AT2
elseif strcmp(Req,"AT2")
    figure(2)
    subplot(2,1,1)
    plot([0, 45],[30,30],'k--','LineWidth',2)
    plot([0, 45],[50,50],'k--','LineWidth',2)
    plot([0, 45],[90,90],'k--','LineWidth',2)

% Only for EKF
elseif strcmp(Req,"EKF")
    figure(2)
    subplot(1,1,1)
    ylim([0,3])

% Only for PM
elseif strcmp(Req,"PM")
    figure(3)
    subplot(2,1,1)
    hold on
    grid on
    for jj = 1:length(signalsHecate)
        plot(signalsHecate(jj).t,round(signalsHecate(jj).x(:,1)),"color",colorHecate(jj,:))
    end

    for jj = 1:length(signalsStaliro)
        plot(signalsStaliro(jj).t,round(signalsStaliro(jj).x(:,1)),"color",colorSTaliro(jj,:))
    end

    subplot(2,1,2)
    hold on
    grid on
    for jj = 1:length(signalsHecate)
        plot(signalsHecate(jj).t,round(signalsHecate(jj).x(:,2)),"color",colorHecate(jj,:))
    end

    for jj = 1:length(signalsStaliro)
        plot(signalsStaliro(jj).t,round(signalsStaliro(jj).x(:,2)),"color",colorSTaliro(jj,:))
    end

    sgtitle("Input signals for model PM",'FontSize',20)

% Only for TL
elseif strcmp(Req,"TL")
    figure(3)

    subplot(2,1,1)
    hold on
    grid on
    for jj = 1:length(signalsHecate)
        plot(signalsHecate(jj).t,signalsHecate(jj).x(:,1),"color",colorHecate(jj,:))
    end

    for jj = 1:length(signalsStaliro)
        plot(signalsStaliro(jj).t,round(signalsStaliro(jj).x(:,1)),"color",colorSTaliro(jj,:))
    end

    subplot(2,1,2)
    hold on
    grid on
    for jj = 1:length(signalsHecate)
        plot(signalsHecate(jj).t,signalsHecate(jj).x(:,2),"color",colorHecate(jj,:))
    end

    for jj = 1:length(signalsStaliro)
        plot(signalsStaliro(jj).t,round(signalsStaliro(jj).x(:,2)),"color",colorSTaliro(jj,:))
    end
    sgtitle("Input signals for model TL",'FontSize',20)

    figure(4)
    hold on
    grid on
    for jj = 1:length(signalsHecate)
        plot(signalsHecate(jj).t,((signalsHecate(jj).y(:,1) == 2) | ((signalsHecate(jj).y(:,2) == 2))),"color",colorHecate(jj,:))
    end

    for jj = 1:length(signalsStaliro)
        plot(signalsStaliro(jj).t,((signalsStaliro(jj).y(:,1) == 2) | ((signalsStaliro(jj).y(:,2) == 2))),"color",colorSTaliro(jj,:))
    end
    title("Output signal for model TL",'FontSize',20)

% Only for EU
elseif strcmp(Req,"EU")
    figure(4)

    subplot(2,1,1)
    hold on
    grid on
    for jj = 1:length(signalsHecate)
        plot(signalsHecate(jj).t,abs(signalsHecate(jj).y(:,1)-1),"color",colorHecate(jj,:))
    end

    for jj = 1:length(signalsStaliro)
        plot(signalsStaliro(jj).t,abs(round(signalsStaliro(jj).y(:,1))-1),"color",colorSTaliro(jj,:))
    end
    plot([0, 10],[0.01,0.01],'k--','LineWidth',2)
    plot([0, 10],[-0.01,-0.01],'k--','LineWidth',2)

    subplot(2,1,2)
    hold on
    grid on
    for jj = 1:length(signalsHecate)
        plot(signalsHecate(jj).t,abs(signalsHecate(jj).y(:,2)-signalsHecate(jj).y(:,3)),"color",colorHecate(jj,:))
    end

    for jj = 1:length(signalsStaliro)
        plot(signalsStaliro(jj).t,abs(round(signalsStaliro(jj).y(:,2))-signalsHecate(jj).y(:,3)),"color",colorSTaliro(jj,:))
    end
    plot([0, 10],[0.01,0.01],'k--','LineWidth',2)
    plot([0, 10],[-0.01,-0.01],'k--','LineWidth',2)
end

%% Additional functions
function outputSettings(modelName)

% Make sure the time and output are saved
timeSave = get_param(modelName,'SaveTime');
if ~strcmp(timeSave,'on')
    set_param(modelName,'SaveTime','on');
    warning('The model is not saving the time array. The model settings have been changed to return the time array as output of the model.') 
end

outputSave = get_param(modelName,'SaveOutput');
if ~strcmp(outputSave,'on')
    set_param(modelName,'SaveOutput','on');
    warning('The model is not saving the output of the simulation. The model settings have been changed to return the output of the model in the chosen format.') 
end

outputFormat = get_param(modelName,'ReturnWorkspaceOutputs');
if ~strcmp(outputFormat,'on')
    set_param(modelName,'ReturnWorkspaceOutputs','on');
    warning('The model is not returning the simulation results as a single variable. The model settings have been changed accordingly.') 
end

% Set the save name for time and output
outputName = get_param(modelName,'TimeSaveName');
if ~strcmp(outputName,'tOut')
    set_param(modelName,'TimeSaveName','tOut');
    warning('The model is not returning the simulation time with the name ""tOut"". The model settings have been changed accordingly.') 
end

outputName = get_param(modelName,'OutputSaveName');
if ~strcmp(outputName,'yOut')
    set_param(modelName,'OutputSaveName','yOut');
    warning('The model is not returning the simulation output with the name ""yOut"". The model settings have been changed accordingly.') 
end

end