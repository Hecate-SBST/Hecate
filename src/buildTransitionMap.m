function buildTransitionMap(blockPath, stepTable, transTable, fitTable)
% This function creates or replaces the Stateflow Chart that represents the
% hierarchical step sequence of the Test Assessment block.
%
%           [stepTable_new, transTable_new] = buildTransitionMap(blockPath, stepTable, transTable, fitTable)
%
%   E.g.:   [stepTable_new, transTable_new] = buildTransitionMap("vdp/Test Assessment", stepTable, transTable, fitTable)
%
% Input:
%   blockPath: char array containing the path to the Test Assessment block.
%
%   stepTable: Table containing the sorted data on each assessments step.
%
%   transTable: Table containing the sorted data on each transition.
%
%   fitTable: Table containing the sorted data on the fitness functions.
%
% (C) 2022, Federico Formica, Tony Fan, McMaster University
% (C) 2024, Federico Formica, McMaster University

global verifyCount;

% Define model name
strTemp = split(blockPath,"/");
modelName = strTemp(1);

% Add two new fields to stepTable for the state handle and name of the
% output variable.
stepTableNew = stepTable;
stepTableNew.StateHandle = cell(size(stepTable,1),1);

% Add a new field to the transTable for the transition handle.
transTableNew = cell2table(cell(0,size(transTable,2)+3),'VariableNames', ...
    [transTable.Properties.VariableNames,'TransHandle','JunctionSource','JunctionDest']);

% Create JunctionTable
junctionTable = cell2table(cell(0,3),'VariableNames',{'Name','JunctionHandle','ParentStep'});

%% Add a blank StateFlow Chart

transMap_name = "FitnessConverter_Hecate"; % Name of the Stateflow Chart block in Simulink
min_name = "Min_Hecate";                    % Name of the minimum operator block for the fitness values
outport_name = "Outport_Fit_Hecate";        % Name of the outport block for the fitness value
delay_name = "Delay_Hecate";                % Name of the delay operator block for the fitness value

blockNames = [transMap_name; min_name; outport_name; delay_name];

% Remove blocks if they already exist
for ii = 1:length(blockNames)
    if getSimulinkBlockHandle(modelName + "/" + blockNames(ii)) > 0
        delete_block(modelName + "/" + blockNames(ii))
    end
end

% Remove broken lines
delete_line(find_system(modelName, "FindAll", "on", "Type", "line", "Connected", "off"))

% Create the blank Stateflow Chart
rt = sfroot;
chart0 = find(rt,"-isa","Stateflow.Chart");
add_block("sflib/Chart",modelName + "/" + transMap_name)
chartTotal = find(rt,"-isa","Stateflow.Chart");
transMapHandle = find(setdiff(chartTotal,chart0),"-isa","Stateflow.Chart");
transMapHandle(end).Locked = false;

% Throw warning message if the library block is among the handles.
if length(transMapHandle) > 1
    idx = find(~strcmp({transMapHandle.Path},"sflib/Chart"),1);
    transMapHandle = transMapHandle(idx);
    warning("The code is unexpectedly considering also the template Stateflow Chart block. " + ...
        "If an error occurs, try to rerun the code.\nThe state and transitions will be added to the block %s.\n",transMapHandle.Path)
end

%% Create the states inside the Stateflow Chart

height = 60;       % Minimum state height
dh = 60;            % Height increase between substates
width = 100;        % Minimum state width
dw = 30+6*size(stepTableNew,1);            % Width increase between same level states

xc = 0;             % x-coordinate of the cursor

for ii = 1:size(stepTableNew,1)

    % Get temporary position parameters
    stepTableTemp = stepTableNew(contains(stepTableNew.Name,stepTableNew.Name{ii}) & stepTableNew.Hierarchy > stepTableNew.Hierarchy(ii),:);
    stepTableTemp = [stepTableNew(ii,:); stepTableTemp];
    n_substate = size(stepTableTemp,1)-1;
    n_sublevel = max(stepTableTemp.Hierarchy)-stepTableNew.Hierarchy(ii);

    pos = zeros(1,4);
    pos(1) = xc;                            % Horizontal position of state top-left corner
    pos(2) = -(height/2+dh*n_sublevel);     % Vertical position of state top-left corner
    pos(3) = width;                         % State width
    pos(4) = height+2*dh*n_sublevel;        % State height

    % Increase state width if substates are present
    for jj = 1:n_substate
        pos(3) = pos(3)+width+dw;
        if stepTableTemp.Hierarchy(jj) < stepTableTemp.Hierarchy(jj+1)
            pos(3) = pos(3)+dw;
        end
    end

    % Define value of fitness inside the state
    stateText = "";

    for jj = 1:size(fitTable,1)
        if contains(stepTableNew.Name{ii},fitTable.Step{jj})
            stateText = stateText + fitTable.Name{jj} + " = " + fitTable.Func{jj} + ";" + newline;
        else
            stateText = stateText + fitTable.Name{jj} + " = Inf;" + newline;
        end
    end

    % Create the state
    strTemp = split(stepTableNew.Name{ii},".");
    stateName = strTemp{end};

    state_temp = Stateflow.State(transMapHandle);
    state_temp.Position = pos;
    state_temp.LabelString = string(stateName) + newline + stateText;

    stepTableNew.StateHandle(ii) = {state_temp};

    % If index == 1 and IsWhenSubStep == true, add junction
    if stepTableNew.Index(ii) == 1 && stepTableNew.IsWhenSubStep(ii) == 1
        junc_temp = Stateflow.Junction(transMapHandle);
        junc_temp.Position.Center = [xc-dw, 0];

        junctionName = "HecateJunction_" + num2str(size(junctionTable,1)+1);
        strTemp = split(stepTableNew.Name{ii},".");
        parentName = join(strTemp(1:end-1),".");
        junctionTable = [junctionTable; {junctionName, junc_temp, parentName}];
    end

    % If index == 1, add default transition
    if stepTableNew.Index(ii) == 1
        transDef_temp = Stateflow.Transition(transMapHandle);
        transDef_temp.SourceEndPoint = [xc-dw/2, -height/2];
        transDef_temp.SourceOClock = 6;

        if stepTableNew.IsWhenSubStep(ii) == 1
            % Connect default transition to the junction
            transDef_temp.Destination = junc_temp;
            transDef_temp.DestinationOClock = 3;
        else
            % Connect default transition to the first state
            transDef_temp.Destination = state_temp;
            transDef_temp.DestinationOClock = 9;
        end
        transDef_temp.MidPoint = [xc-dw/2, -height/4];
    end

    % If IsWhenSubStep == true, connect state to junction
    if stepTableNew.IsWhenSubStep(ii) == 1

        % Get junction handle
        strTemp = split(stepTableNew.Name{ii},".");
        stepParent = join(strTemp(1:end-1),".");
        idxJunction = strcmp(stepParent,junctionTable.ParentStep);
        juncLine = junctionTable(idxJunction,:);

        % Create transitions from junction
        trans_temp = Stateflow.Transition(transMapHandle);
        trans_temp.Source = juncLine.JunctionHandle;
        trans_temp.Destination = stepTableNew.StateHandle{ii};
        trans_temp.LabelString = "[" + stepTableNew.WhenCondition{ii} + "]";
        trans_temp.SourceOClock = 3;
        src_Point = trans_temp.SourceEndPoint;
        dst_Point = trans_temp.DestinationEndPoint;
        dst_Point(2) = 0;
        trans_temp.DestinationEndPoint = dst_Point;
        mid_Point = [(src_Point(1)+dst_Point(1))/2, 0];
        trans_temp.MidPoint = mid_Point;
        transLine = [{""}, ...
            stepTableNew.Index(ii), ...
            stepTableNew.WhenCondition(ii), ...
            stepTableNew.Name(ii), ...
            {trans_temp}, ...
            {juncLine.Name}, ...
            {""}];
        transTableNew = [transTableNew; transLine];

        % Define transition condition back from junction
        idx_prestep = stepTableNew.Hierarchy == stepTableNew.Hierarchy(ii) & stepTableNew.Index < stepTableNew.Index(ii) & contains(stepTableNew.Name,stepParent);
        cond_prestep = stepTableNew.WhenCondition(idx_prestep);

        if ~isempty(cond_prestep)
            transCond = join(cond_prestep,")|(");
            transCond = "(" + string(transCond) + ")";
        else
            transCond = "";
        end

        if ~isempty(stepTableNew.WhenCondition{ii})
            if ~isempty(transCond)
                transCond = transCond + "|";
            end
            transCond = transCond + "~(" + stepTableNew.WhenCondition{ii} + ")";
        end

        % Create transitions to junction
        trans_temp = Stateflow.Transition(transMapHandle);
        trans_temp.Source = stepTableNew.StateHandle{ii};
        trans_temp.Destination = juncLine.JunctionHandle;
        trans_temp.LabelString = "[" + transCond + "]";
        trans_temp.SourceOClock = 9;
        src_Point = trans_temp.SourceEndPoint;
        dst_Point = trans_temp.DestinationEndPoint;
        dst_Point(2) = 0;
        trans_temp.DestinationEndPoint = dst_Point;
        mid_Point = [(src_Point(1)+dst_Point(1))/2, 0];
        trans_temp.MidPoint = mid_Point;
        transLine = [stepTableNew.Name(ii), ...
            stepTableNew.Index(ii), ...
            {"[" + transCond + "]"}, ...
            {""}, ...
            {trans_temp}, ...
            {""}, ...
            {juncLine.Name}];
        transTableNew = [transTableNew; transLine];

    end

    % Update cursor position
    xc = xc+width+dw;

    if ii < size(stepTableNew,1) && stepTableNew.Hierarchy(ii) > stepTableNew.Hierarchy(ii+1)
        diffHier = stepTableNew.Hierarchy(ii)-stepTableNew.Hierarchy(ii+1);
        xc = xc+dw*diffHier;
    end

end

%% Create the transitions

% Add the proper transitions
for ii  = 1:size(transTable,1)
    transLine = transTable(ii,:);

    trans_temp = Stateflow.Transition(transMapHandle);
    trans_temp.Source = stepTableNew.StateHandle{strcmp(stepTableNew.Name,transLine.Step)};
    trans_temp.Destination = stepTableNew.StateHandle{strcmp(stepTableNew.Name,transLine.NextStep)};
    trans_temp.LabelString = "[" + transLine.Condition{1} + "]";
    trans_temp.SourceOClock = 3;
    src_Point = trans_temp.SourceEndPoint;
    dst_Point = trans_temp.DestinationEndPoint;
    dst_Point(2) = 0;
    trans_temp.DestinationEndPoint = dst_Point;
    mid_Point = [(src_Point(1)+dst_Point(1))/2, 0];
    trans_temp.MidPoint = mid_Point;

    transTableNew = [transTableNew; [table2cell(transLine),{trans_temp},{""},{""}]];
end

%% Add the symbols

% Get model signals used in the test assessment block
inputTA = sltest.testsequence.findSymbol(blockPath, "Scope", "Input");

% Input symbols
input = cell(length(inputTA),1);
for ii = 1:length(inputTA)
    input_temp = Stateflow.Data(transMapHandle);
    input_temp.Name = inputTA{ii};
    input_temp.Scope = "Input";
    input(ii) = {input_temp};
end

% Parameter symbols
paramTA = sltest.testsequence.findSymbol(blockPath, "Scope", "Parameter");
param = cell(length(paramTA),1);
for ii = 1:length(paramTA)
    if strcmp(paramTA{ii},"Active_Scenario_Index")
        continue
    end
    param_temp = Stateflow.Data(transMapHandle);
    param_temp.Name = paramTA{ii};
    param_temp.Scope = "Parameter";
    param(ii) = {param_temp};
end

% Output symbols
output = cell(size(fitTable,1),1);
for ii = 1:size(fitTable,1)
    output_temp = Stateflow.Data(transMapHandle);
    output_temp.Name = fitTable.Name{ii};
    output_temp.Scope = "Output";
    output(ii) = {output_temp};
end

%% Add min, delay and outport block for fitness signal

% Get Stateflow Chart position
chartPosition = get_param(modelName + "/" + transMap_name,"Position");

% Add min block
add_block("simulink/Math Operations/MinMax", modelName + "/" + min_name)
set_param(modelName + "/" + min_name,"Inputs",num2str(verifyCount+1));
posTemp = [chartPosition(3)+50, chartPosition(2), chartPosition(3)+50+30, ...
    chartPosition(2)+(chartPosition(4)-chartPosition(2))*(verifyCount+1)/verifyCount];
set_param(modelName + "/" + min_name,"Position",posTemp);

% Add delay block
add_block("simulink/Discrete/Delay",modelName + "/" + delay_name)
set_param(modelName + "/" + delay_name,"DelayLength","1");
set_param(modelName + "/" + delay_name,"InitialCondition","Inf");
set_param(modelName + "/" + delay_name,"Orientation","left");
set_param(modelName + "/" + delay_name,"Position", ...
    [posTemp(1), posTemp(4)+30, posTemp(3), posTemp(4)+30+30]);

% Add outport
add_block("simulink/Commonly Used Blocks/Out1",modelName + "/" + outport_name)
set_param(modelName + "/" + outport_name,"Position", ...
    [posTemp(3)+50, (posTemp(2)+posTemp(4))/2-7, posTemp(3)+50+30, (posTemp(2)+posTemp(4))/2+7]);

% Link input signals to Chart
lines_param = get_param(blockPath,"LineHandles");
lines_handle = lines_param.Inport;

port_name_TA = get_param(blockPath,"Blocks");
port_name_TA = port_name_TA(~contains(port_name_TA," "));

if length(port_name_TA) ~= length(inputTA)
    error("The number of Input symbol in the Test Assessment block does not match the number of ports on the block. Please remove any output signal from the Test Assessment block.")
end

for ii = 1:length(lines_handle)
    
    src_block_handle = get_param(lines_handle(ii),"SrcBlockHandle");
    src_block_name = get_param(src_block_handle,"Name");

    src_port_handle = get_param(lines_handle(ii),"SrcPortHandle");
    src_port_number = get_param(src_port_handle,"PortNumber");

    dest_port_number = find(strcmp(inputTA,port_name_TA{ii}),1);
    add_line(modelName,src_block_name + "/" + num2str(src_port_number),transMap_name + "/" + num2str(dest_port_number))
end

% Link Chart to min block
for ii = 1:verifyCount
    add_line(modelName,transMap_name + "/" + num2str(ii),min_name + "/" + num2str(ii))
end

% Link min block to delay
add_line(modelName,min_name + "/1",delay_name + "/1")

% Link delay to min block (last gate)
add_line(modelName,delay_name + "/1",min_name + "/" + num2str(verifyCount+1))

% Link min block to outport
add_line(modelName,min_name + "/1",outport_name + "/1")

end