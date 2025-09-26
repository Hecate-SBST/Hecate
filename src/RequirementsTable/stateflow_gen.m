% Script that generate a Stateflow according to the information saved in
% a .mat file.


function stateflow_gen(assTable, modelName, reqTable, symbTable, tablesPath)


%% 2 - Create Stateflow Chart in Simulink model

% Save and close all other Simulink models
loadedModels = Simulink.allBlockDiagrams('model');
modelNamesTemp = string(get_param(loadedModels,'Name'));

for ii = 1:length(modelNamesTemp)
    if ~strcmp(modelNamesTemp(ii),modelName)
        save_system(modelNamesTemp{ii})
        close_system(modelNamesTemp{ii})
        warning('The model %s was open during the execution of Hecate. For safety, it has been saved and closed.',modelNamesTemp(ii))
    end
end

% Load the model (if not loaded already)
if ~any(strcmp(modelNamesTemp,modelName))
    load_system(modelName)
end

% Check if Stateflow Chart and other Hecate blocks exist already (and delete them)
chartName = "FitnessConverter_Hecate";
chartPath = modelName + "/" + chartName;
blockNames = [chartName; "Min_Hecate"; "Delay_Hecate"; "Outport_Fit_Hecate"];
for ii = 1:length(blockNames)
    NameTemp = modelName + "/" + blockNames(ii);
    if getSimulinkBlockHandle(NameTemp) > 0
        delete_block(NameTemp)
    end
end

% Delete Delay Prev blocks
delayHandleTemp = Simulink.findBlocksOfType(modelName,"Delay",Simulink.FindOptions("SearchDepth",1));
for ii = 1:length(delayHandleTemp)
    NameTemp = get_param(delayHandleTemp(ii),"Name");
    if startsWith(NameTemp,"HecateDelayPrev")
        delete_block(delayHandleTemp(ii))
    end
end

% Remove broken lines
delete_line(find_system(modelName, 'FindAll', 'on', 'Type', 'line', 'Connected', 'off'))

% Create the empty Stateflow chart
add_block('sflib/Chart',chartPath)
close_system('sflib')

% Find the Chart handle
rootTemp = sfroot;
chartHandle = find(rootTemp,"-isa","Stateflow.Chart","Path",chartPath);
chartHandle.Decomposition = "PARALLEL_AND";

% Define state size
stateWidth = 200;
stateHeight = 100;
stateGap = 50;
x_cursor = 0;
y_cursor = 0;

% Clear temporary variables
clear("*Temp")

%% 3 - Create symbols in the Chart

% ToDo: handle prev functions by creating additional symbols.
% For now, just remove the prev from pre, post and action columns.
prevSymbTable = table('Size',[0,3],'VariableTypes',{'string','string','uint64'}, ...
    'VariableNames',{'PrevName','OrigName','DelaySize'});

for ii = 1:height(reqTable)
    % Remove from preconditions
    [reqTable.PreCond(ii), prevSymbTable] = replacePrev(reqTable.PreCond(ii), prevSymbTable);

    % Remove from postconditions
    [reqTable.PostCond(ii), prevSymbTable] = replacePrev(reqTable.PostCond(ii), prevSymbTable);

    % Remove from robustness functions
    [reqTable.RobustFcn(ii), prevSymbTable] = replacePrev(reqTable.RobustFcn(ii), prevSymbTable);

    % Remove from actions
    [reqTable.Action(ii), prevSymbTable] = replacePrev(reqTable.Action(ii), prevSymbTable);
%     while contains(reqTable.Action(ii),"prev(")
%         reqTable.Action(ii) = regexprep(reqTable.Action(ii),"prev\(([^)]*)\)","$1");
%     end
end

% Create input symbols
for ii = 1:height(symbTable)
    symbolTemp = Stateflow.Data(chartHandle);
    symbolTemp.Name = symbTable.Name(ii);
    symbolTemp.Scope = symbTable.Scope(ii);
    symbolTemp.DataType = symbTable.Type(ii);

    % % % Developer note: the following properties have not been tested. % % %
    symbolTemp.Props.Array.Size = symbTable.Size(ii);
    symbolTemp.Props.InitialValue = symbTable.InitialValue(ii);
    symbolTemp.Props.Complexity = symbTable.Complexity(ii);
%   end
end

% Create robustness symbols
for ii = 1:height(reqTable)
    symbolTemp = Stateflow.Data(chartHandle);
    symbolTemp.Name = sprintf("rob%i",ii);
    symbolTemp.Scope = "Output";
    symbolTemp.DataType = "double";
    symbolTemp.Props.InitialValue = "Inf";
    symbolTemp.Port = ii;
end

% Create prev symbols
for ii = 1:height(prevSymbTable)
    symbolTemp = Stateflow.Data(chartHandle);
    symbolTemp.Name = prevSymbTable.PrevName(ii);
    symbolTemp.Scope = "Input";
    symbolTemp.Props.InitialValue = "0";
end

% Clear temporary variables
clear("*Temp")

%% 4 - Create Assumption_check state

% Compute conjunction of all requirements.
if ~cellfun('isempty',assTable.PreCond)

    assTable.CumPreCond = strings(height(assTable),1);
    assTable.AssFormula = strings(height(assTable),1);
    for ii = 1:height(assTable)
        if assTable.Parent(ii) == ""
            assTable.CumPreCond(ii) = assTable.PreCond(ii);
        else
            idxTemp = find(strcmp(assTable.AssID,assTable.Parent(ii)));
            assTable.CumPreCond(ii) = assTable.CumPreCond(idxTemp) + " && " + assTable.PreCond(ii);
        end
        assTable.AssFormula(ii) = "~(" + assTable.CumPreCond(ii) + ") || (" + assTable.CumPreCond(ii) + " && " + assTable.PostCond(ii) + ")";
    end
    
    assFormula = "(" + join(assTable.AssFormula, ") && (") + ")";
    
    % Create state containing assert statement
    stateReqTemp = Stateflow.State(chartHandle);
    stateReqTemp.LabelString = "Assumptions_check";
    stateReqTemp.ExecutionOrder = 1;
    stateReqTemp.LabelString = string(stateReqTemp.LabelString) + newline + "assert(" + assFormula + ",""One of the model assumptions have been violated."");";
    stateReqTemp.Position = [x_cursor, y_cursor, stateWidth+2*stateGap, 4*stateHeight+5*stateGap];
    x_cursor = x_cursor + (stateWidth+2*stateGap) + stateGap;
    % Clear temporary variables
    clear("*Temp")
end

%% 5 - Create states for each requirement

% % % Developer note: we are currently neglecting the hierarchy % % %
tokenTrue_count = 0;
tokenFalse_count = 0; 
% Loop over requirements
for ii = 1:height(reqTable)
    % Create one state for each requirement
    stateReqTemp = Stateflow.State(chartHandle);
    stateReqTemp.LabelString = sprintf("Requirement_%s",reqTable.ReqID(ii));
    stateReqTemp.Decomposition = "EXCLUSIVE_OR";
    stateReqTemp.ExecutionOrder = ii+1;
    stateReqTemp.Position = [x_cursor, y_cursor, stateWidth+2*stateGap, 4*stateHeight+5*stateGap];

    % Create initial junction and default transition
    junctionTemp = Stateflow.Junction(stateReqTemp);
    junctionTemp.Position.Center = [x_cursor+(stateWidth+2*stateGap)*2/3, y_cursor+(stateHeight+2*stateGap)*2/3];

    transDefTemp = Stateflow.Transition(stateReqTemp);
    transDefTemp.Destination = junctionTemp;
    transDefTemp.SourceEndpoint = [x_cursor+(stateWidth+2*stateGap)*2/3, y_cursor+(stateHeight+2*stateGap)*1/3];
    transDefTemp.DestinationOClock = 12;

    % Move cursor to the right and down
    x_cursor = x_cursor + stateGap;
    y_cursor = y_cursor + stateHeight + 2*stateGap;

    % Create Default state
    stateDefTemp = Stateflow.State(stateReqTemp);
    stateDefTemp.LabelString = "Default";
    stateDefTemp.LabelString = string(stateDefTemp.LabelString) + newline + sprintf("rob%i = Inf;",ii);
    stateDefTemp.Position = [x_cursor, y_cursor, stateWidth, stateHeight];

    % Move cursor down
    y_cursor = y_cursor + stateHeight + stateGap;

    % Create Wait state (if necessary)
    if reqTable.Duration(ii) ~= ""
        stateWaitTemp = Stateflow.State(stateReqTemp);
        stateWaitTemp.LabelString = "Wait";
        stateWaitTemp.LabelString = string(stateWaitTemp.LabelString) + newline + sprintf("rob%i = Inf;",ii);
        stateWaitTemp.Position = [x_cursor, y_cursor, stateWidth, stateHeight];
    end

    % Move cursor down
    y_cursor = y_cursor + stateHeight + stateGap;

    % Create Verify state
    stateVerTemp = Stateflow.State(stateReqTemp);
    stateVerTemp.LabelString = "Verify";
    stateVerTemp.Decomposition = "EXCLUSIVE_OR";
    stateVerTemp.LabelString = string(stateVerTemp.LabelString) + newline + sprintf("rob%i = %s;",ii,reqTable.RobustFcn(ii));
    stateVerTemp.LabelString = string(stateVerTemp.LabelString) + newline + reqTable.Action(ii);
    stateVerTemp.Position = [x_cursor, y_cursor, stateWidth, stateHeight];

    % Create Token_true and Token_false
    if (strcmp(reqTable.RobustFcn(ii),"TOKEN_TRUE")) && tokenTrue_count == 0
        symbolTemp = Stateflow.Data(chartHandle);
        symbolTemp.Name = sprintf("TOKEN_TRUE");
        symbolTemp.Scope = "Local";
        symbolTemp.DataType = "double";
        symbolTemp.Props.InitialValue = "1";
        tokenTrue_count = 1;
    elseif (strcmp(reqTable.RobustFcn(ii),"TOKEN_FALSE")) && tokenFalse_count == 0
        symbolTemp = Stateflow.Data(chartHandle);
        symbolTemp.Name = sprintf("TOKEN_FALSE");
        symbolTemp.Scope = "Local";
        symbolTemp.DataType = "double";
        symbolTemp.Props.InitialValue = "-1";
        tokenFalse_count = 1;
    end

    % Create transitions
    reqTable.PreCond(ii) = erase(reqTable.PreCond(ii),"prev"); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%CHECK

        % 1 - Transition from the initial junction to the Default state
    transTemp = Stateflow.Transition(stateReqTemp);
    transTemp.Source = junctionTemp;
    transTemp.Destination = stateDefTemp;
    transTemp.ExecutionOrder = 1;
    transTemp.LabelString = "[~(" + reqTable.PreCond(ii) + ")]";
    transTemp.DestinationOClock = 12;

        % 2 - Transition from the initial junction to the Wait or Verify state
    transTemp = Stateflow.Transition(stateReqTemp);
    transTemp.Source = junctionTemp;
    if reqTable.Duration(ii) ~= ""
        transTemp.Destination = stateWaitTemp;
    else
        transTemp.Destination = stateVerTemp;
    end
    transTemp.ExecutionOrder = 2;
    transTemp.DestinationOClock = 12;

        % 3 - Transition from the Default state to the Wait or Verify state
    transTemp = Stateflow.Transition(stateReqTemp);
    transTemp.Source = stateDefTemp;
    if reqTable.Duration(ii) ~= ""
        transTemp.Destination = stateWaitTemp;
    else
        transTemp.Destination = stateVerTemp;
    end
    transTemp.ExecutionOrder = 1;
    transTemp.LabelString = "[" + reqTable.PreCond(ii) + "]";
    transTemp.DestinationOClock = 12;

        % 4 - Transition from the Wait state (if present) to the Default state
    if reqTable.Duration(ii) ~= ""
        transTemp = Stateflow.Transition(stateReqTemp);
        transTemp.Source = stateWaitTemp;
        transTemp.Destination = stateDefTemp;
        transTemp.ExecutionOrder = 1;
        transTemp.LabelString = "[~(" + reqTable.PreCond(ii) + ")]";
        transTemp.DestinationOClock = 6;
    end

        % 5 - Transition from the Wait state (if present) to the Verify state
    if reqTable.Duration(ii) ~= ""
        transTemp = Stateflow.Transition(stateReqTemp);
        transTemp.Source = stateWaitTemp;
        transTemp.Destination = stateVerTemp;
        transTemp.ExecutionOrder = 2;
        transTemp.LabelString = "[et >= " + reqTable.Duration(ii) + "]";
        transTemp.DestinationOClock = 12;
    end

        % 6 - Transition from the Verify state to the Default state
    transTemp = Stateflow.Transition(stateReqTemp);
    transTemp.Source = stateVerTemp;
    transTemp.Destination = stateDefTemp;
    transTemp.ExecutionOrder = 1;
    transTemp.LabelString = "[~(" + reqTable.PreCond(ii) + ")]";
    transTemp.DestinationOClock = 6;

    % Move the cursor to the right and reset vertical position
    x_cursor = x_cursor + stateWidth + 2*stateGap;
    y_cursor = 0;

    % Clear temporary variables
    clear("*Temp")

end

% Clear temporary variables
clear("*Temp")

%Create symbol for startup and prev 
%NEED TO ADD IF STATEMENT TO CHECK IF IT IS NEEDED
% symbolTemp = Stateflow.Data(chartHandle);
% symbolTemp.Name = sprintf("prev");
% symbolTemp.Scope = "Input";

% symbolTemp = Stateflow.Data(chartHandle);
% symbolTemp.Name = sprintf("isStartup");
% symbolTemp.Scope = "Input";

% Clear temporary variables
clear("*Temp")

%% 6 - Connect Hecate to existing model

% Get position of Stateflow Chart
posChartTemp = get_param(chartPath,"Position");
centerChartTemp = round([(posChartTemp(1)+posChartTemp(3))/2, (posChartTemp(2)+posChartTemp(4))/2]);

% Create min block
minPathTemp = modelName + "/" + blockNames(2);
add_block("simulink/Math Operations/MinMax",minPathTemp);
set_param(minPathTemp,"Function","min","Inputs",num2str(height(reqTable)+1));
posMinTemp = [posChartTemp(3)+100, posChartTemp(2), posChartTemp(3)+135, ...
    posChartTemp(2)+(posChartTemp(4)-posChartTemp(2))*(height(reqTable)+1)/height(reqTable)];
set_param(minPathTemp,"Position",posMinTemp);

% Create delay block
delayPathTemp = modelName + "/" + blockNames(3);
add_block("simulink/Discrete/Delay",delayPathTemp);
set_param(delayPathTemp,"DelayLength","1","InitialCondition","Inf");
posDelayTemp = [posMinTemp(1), posMinTemp(4)+40, posMinTemp(3), posMinTemp(4)+75];
set_param(delayPathTemp,"Orientation","left","Position",posDelayTemp);

% Create outport block
nOutports = length(Simulink.findBlocksOfType(modelName,"Outport",Simulink.FindOptions("SearchDepth",1)));
outPathTemp = modelName + "/" + blockNames(4);
add_block("simulink/Commonly Used Blocks/Out1",outPathTemp);
set_param(outPathTemp,"Port",num2str(nOutports+1));
posOutTemp = [posMinTemp(3)+100, (posMinTemp(2)+posMinTemp(4))/2-7, ...
    posMinTemp(3)+130, (posMinTemp(2)+posMinTemp(4))/2+7];
set_param(outPathTemp,"Position",posOutTemp);

% Connect Stateflow Chart inputs to the model
linesHandleTemp = getfield(get_param(tablesPath,"LineHandles"), "Inport");
for ii = 1:length(linesHandleTemp)
    sourceBlockTemp = get_param(linesHandleTemp(ii),"SrcBlockHandle");
    sourcePortTemp = get_param(linesHandleTemp(ii),"SrcPortHandle");
    sourceTemp = get_param(sourceBlockTemp,"Name") + "/" + num2str(get_param(sourcePortTemp,"PortNumber"));
    add_line(modelName, sourceTemp, chartName + "/" + num2str(ii), "autorouting", "smart")
end

% Connect Stateflow Chart prev inputs
nInputs = length(linesHandleTemp);
portsInputsNameTemp = symbTable.Name(strcmp(symbTable.Scope,"Input"));
linesOutputHandlesTemp = getfield(get_param(tablesPath,"LineHandles"), "Outport");
portsOutputsNameTemp = symbTable.Name(strcmp(symbTable.Scope,"Output"));

for ii = 1:height(prevSymbTable)

    % Add delay block
    delayPathTemp = modelName + "/" + "HecateDelayPrev" + string(ii);
    add_block("simulink/Discrete/Delay",delayPathTemp);
    set_param(delayPathTemp,"DelayLength",string(prevSymbTable.DelaySize(ii)),"InitialCondition","0");
    centerBlockTemp = posChartTemp(2)+(posChartTemp(4)-posChartTemp(2))/ ...
        (nInputs+height(prevSymbTable))*(nInputs+ii-0.5);
    posDelayTemp = [posChartTemp(1)-40-35, centerBlockTemp-17, posChartTemp(1)-40, centerBlockTemp+17];
    set_param(delayPathTemp,"Orientation","right","Position",posDelayTemp);

    % Connect delay block with source signal
    idxTemp = find(strcmp(prevSymbTable.OrigName(ii),portsInputsNameTemp),1);
    if isempty(idxTemp)
        idxTemp = find(strcmp(prevSymbTable.OrigName(ii),portsOutputsNameTemp),1);
        sourceBlockTemp = get_param(linesOutputHandlesTemp(idxTemp),"SrcBlockHandle");
        sourcePortTemp = get_param(linesOutputHandlesTemp(idxTemp),"SrcPortHandle");
        sourceTemp = get_param(sourceBlockTemp,"Name") + "/" + num2str(get_param(sourcePortTemp,"PortNumber"));
    else
        sourceBlockTemp = get_param(linesHandleTemp(idxTemp),"SrcBlockHandle");
        sourcePortTemp = get_param(linesHandleTemp(idxTemp),"SrcPortHandle");
        sourceTemp = get_param(sourceBlockTemp,"Name") + "/" + num2str(get_param(sourcePortTemp,"PortNumber"));
    end
    add_line(modelName, sourceTemp, "HecateDelayPrev" + string(ii) + "/1", "autorouting", "smart")

    % Connect delay block with Stateflow Chart
    add_line(modelName, "HecateDelayPrev" + string(ii) + "/1", chartName + "/" + num2str(nInputs+ii), "autorouting", "smart")

end

% Connect Stateflow Chart outputs to Min block
for ii = 1:height(reqTable)
    add_line(modelName, chartName + "/" + num2str(ii), blockNames(2) + "/" + num2str(ii), "autorouting", "smart");
end

% Connect Min block to Delay block and vice versa
add_line(modelName, blockNames(2) + "/" + "1", blockNames(3) + "/" + "1", "autorouting", "smart");
add_line(modelName, blockNames(3) + "/" + "1", blockNames(2) + "/" + num2str(height(reqTable)+1), "autorouting", "smart");

% Connect Min block to Outport
add_line(modelName, blockNames(2) + "/" + "1", blockNames(4) + "/" + "1", "autorouting", "smart");

% Clear temporary variables
clear("*Temp")

end

function [newStr,prevSymbTable] = replacePrev(oldStr,prevSymbTable)

    count = height(prevSymbTable)+1;
    newStr = oldStr;

    % Keep looping until all prev have been replaced
    while contains(newStr,"prev(")

        % Find the first match using Regexp
        signalStr = regexp(newStr,"prev\(([^)]*)\)","match","once");

        % Find innermost prev (if multiple prev are one within the other)
        idxStr = regexp(signalStr,"prev\(","end");
        nameTemp = extractBetween(signalStr,idxStr(end)+1,strlength(signalStr)-1);

        % Check if the symbol alredy exists in prevSymbTable
        if any(strcmp(nameTemp+"Prev",prevSymbTable.PrevName))
            newStr = replace(newStr,"prev("+nameTemp+")",nameTemp+"Prev");

        % Check if the symbol is the prev of an already existing symbol in prevSymbTable
        elseif any(strcmp(nameTemp,prevSymbTable.PrevName))
            prevSymbTable(count,:) = {"","",0};
            idxTemp = find(strcmp(nameTemp,prevSymbTable.PrevName),1);
            prevSymbTable.PrevName(count) = nameTemp+"Prev";
            prevSymbTable.OrigName(count) = prevSymbTable.OrigName(idxTemp);
            prevSymbTable.DelaySize(count) = prevSymbTable.DelaySize(idxTemp)+1;
            newStr = replace(newStr,"prev("+nameTemp+")",nameTemp+"Prev");
            count = count+1;

        % Create a completely new symbol in prevSymbTable
        else
            prevSymbTable(count,:) = {"","",0};
            prevSymbTable.PrevName(count) = nameTemp+"Prev";
            prevSymbTable.OrigName(count) = nameTemp;
            prevSymbTable.DelaySize(count) = 1;
            newStr = replace(newStr,"prev("+nameTemp+")",nameTemp+"Prev");
            count = count+1;

        end
    end

end
