function [stepTable_new, transTable_new, junctionTable] = buildTransitionMap(blockPath, stepTable, transTable, fitTable)
% This function creates or replaces the Stateflow Chart that represents the
% hierarchical step sequence of the Test Assessment block.
%
%           [stepTable_new, transTable_new] = buildTransitionMap(blockPath, stepTable, transTable, fitTable)
%
%   E.g.:   [stepTable_new, transTable_new] = buildTransitionMap('vdp/Test Assessment', stepTable, transTable, fitTable)
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
% Output:
%   stepTable_new: Same structure as stepTable, but containing also the
%   handle to the State corresponding to the step and the name of the
%   output variable associated to the step.
%
%   transTable_new: Same structure as transTable, but containing also the
%   handle to the State Transition corresponding to the step transition.
%
%   junctionTable: Table containing the following fields
%       Name: Name of the junction, in the format 'HecateJunction_'+number.
%       JunctionHandle: Handle to the Stateflow junction.
%       ParentStep: Name of the parent state that contains the junction.

% % Load system to add the blocks and read the Stateflow (remove it if the
% % model is opened before)
% load_system(modelname)

global verifyCount;

% Define model name
temp_str = split(blockPath,'/');
modelname = temp_str{1};

% Add two new fields to stepTable for the state handle and name of the
% output variable.
stepTable_new = stepTable;
stepTable_new.StateHandle = cell(size(stepTable,1),1);

% Add a new field to the transTable for the transition handle.
transTable_new = cell2table(cell(0,size(transTable,2)+3),'VariableNames',[transTable.Properties.VariableNames,'TransHandle','JunctionSource','JunctionDest']);
% transTable_new.TransHandle = cell(size(transTable,1),1);
% transTable_new.JunctionSource = cell(size(transTable,1),1);
% transTable_new.JunctionDest = cell(size(transTable,1),1);

% Create JunctionTable
junctionTable = cell2table(cell(0,3),'VariableNames',{'Name','JunctionHandle','ParentStep'});

%% Add a blank StateFlow Chart

transMap_name = 'FitnessConverter_Hecate'; % Name of the Stateflow Chart block in Simulink
min_name = 'Min_Hecate';                    % Name of the minimum operator block for the fitness values
outport_name = 'Outport_Fit_Hecate';        % Name of the outport block for the fitness value
delay_name = 'Delay_Hecate';                % Name of the delay operator block for the fitness value

block_names = {transMap_name; min_name; outport_name; delay_name};

% Remove blocks if they already exist
for ii = 1:length(block_names)
    if getSimulinkBlockHandle([modelname, '/', block_names{ii}]) > 0
        delete_block([modelname, '/', block_names{ii}])
    end
end

% Remove broken lines
delete_line(find_system(modelname, 'FindAll', 'on', 'Type', 'line', 'Connected', 'off'))

% Create the blank Stateflow Chart
rt = sfroot;
chart_0 = find(rt,"-isa","Stateflow.Chart");
add_block('sflib/Chart',[modelname, '/', transMap_name])
chart_total = find(rt,"-isa","Stateflow.Chart");
transMap_handle = find(setdiff(chart_total,chart_0),"-isa","Stateflow.Chart");
transMap_handle(end).Locked = false;
fprintf('Number of Stateflow Chart block handles: %i.\n',length(transMap_handle))

% Throw warning message if the library block is among the handles.
if length(transMap_handle) > 1
    idx = find(~strcmp({transMap_handle.Path},'sflib/Chart'),1);
    transMap_handle = transMap_handle(idx);
    warning('The code is unexpectedly considering also the template Stateflow Chart block. If an error occurs, try to rerun the code.\nThe state and transitions will be added to the block %s.\n',transMap_handle.Path)
end

%% Create the states inside the Stateflow Chart

height = 60;       % Minimum state height
dh = 60;            % Height increase between substates
width = 100;        % Minimum state width
dw = 30+6*size(stepTable_new,1);            % Width increase between same level states

xc = 0;             % x-coordinate of the cursor

for ii = 1:size(stepTable_new,1)

    % Get temporary position parameters
    stepTable_temp = stepTable_new(contains(stepTable_new.Name,stepTable_new.Name{ii}) & stepTable_new.Hierarchy > stepTable_new.Hierarchy(ii),:);
    stepTable_temp = [stepTable_new(ii,:); stepTable_temp];
    n_substate = size(stepTable_temp,1)-1;
    n_sublevel = max(stepTable_temp.Hierarchy)-stepTable_new.Hierarchy(ii);

    pos = zeros(1,4);
    pos(1) = xc;                            % Horizontal position of state top-left corner
    pos(2) = -(height/2+dh*n_sublevel);     % Vertical position of state top-left corner
    pos(3) = width;                         % State width
    pos(4) = height+2*dh*n_sublevel;        % State height

    % Increase state width if substates are present
    for jj = 1:n_substate
        pos(3) = pos(3)+width+dw;
        if stepTable_temp.Hierarchy(jj) < stepTable_temp.Hierarchy(jj+1)
            pos(3) = pos(3)+dw;
        end
    end

    % Define value of fitness inside the state
    stateText = '';

    for jj = 1:size(fitTable,1)
        if contains(stepTable_new.Name{ii},fitTable.Step{jj})
            stateText = [stateText, fitTable.Name{jj}, ' = ', fitTable.Func{jj}, ';', newline];
        else
            stateText = [stateText, fitTable.Name{jj}, ' = Inf;', newline];
        end
    end

    % Create the state
    temp_str = split(stepTable_new.Name{ii},'.');
    stateName = temp_str{end};

    state_temp = Stateflow.State(transMap_handle);
    state_temp.Position = pos;
    state_temp.LabelString = [stateName, newline, stateText];

    stepTable_new.StateHandle(ii) = {state_temp};

    % If index == 1 and IsWhenSubStep == true, add junction
    if stepTable_new.Index(ii) == 1 && stepTable_new.IsWhenSubStep(ii) == 1
        junc_temp = Stateflow.Junction(transMap_handle);
        junc_temp.Position.Center = [xc-dw, 0];

        junctionName = ['HecateJunction_',num2str(size(junctionTable,1)+1)];
        temp_str = split(stepTable_new.Name{ii},'.');
        parentName = join(temp_str(1:end-1),'.');
        junctionTable = [junctionTable; {junctionName, junc_temp, parentName}];
    end

    % If index == 1, add default transition
    if stepTable_new.Index(ii) == 1
        transDef_temp = Stateflow.Transition(transMap_handle);
        transDef_temp.SourceEndPoint = [xc-dw/2, -height/2];
        transDef_temp.SourceOClock = 6;

        if stepTable_new.IsWhenSubStep(ii) == 1
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
    if stepTable_new.IsWhenSubStep(ii) == 1

        % Get junction handle
        temp_str = split(stepTable_new.Name{ii},'.');
        stepParent = join(temp_str(1:end-1),'.');
        idxJunction = strcmp(stepParent,junctionTable.ParentStep);
        juncLine = junctionTable(idxJunction,:);

        % Create transitions from junction
        trans_temp = Stateflow.Transition(transMap_handle);
        trans_temp.Source = juncLine.JunctionHandle;
        trans_temp.Destination = stepTable_new.StateHandle{ii};
        trans_temp.LabelString = ['[', stepTable_new.WhenCondition{ii}, ']'];
        trans_temp.SourceOClock = 3;
        src_Point = trans_temp.SourceEndPoint;
        dst_Point = trans_temp.DestinationEndPoint;
        dst_Point(2) = 0;
        trans_temp.DestinationEndPoint = dst_Point;
        mid_Point = [(src_Point(1)+dst_Point(1))/2, 0];
        trans_temp.MidPoint = mid_Point;
        transLine = [{''}, ...
            stepTable_new.Index(ii), ...
            stepTable_new.WhenCondition(ii), ...
            stepTable_new.Name(ii), ...
            {trans_temp}, ...
            {juncLine.Name}, ...
            {''}];
        transTable_new = [transTable_new; transLine];

        % Define transition condition back from junction
        idx_prestep = stepTable_new.Hierarchy == stepTable_new.Hierarchy(ii) & stepTable_new.Index < stepTable_new.Index(ii) & contains(stepTable_new.Name,stepParent);
        cond_prestep = stepTable_new.WhenCondition(idx_prestep);

        if ~isempty(cond_prestep)
            transCond = join(cond_prestep,')|(');
            transCond = ['(',char(transCond),')'];
        else
            transCond = '';
        end

        if ~isempty(stepTable_new.WhenCondition{ii})
            if ~isempty(transCond)
                transCond = [transCond,'|'];
            end
            transCond = [transCond, '~(', stepTable_new.WhenCondition{ii}, ')'];
        end

        % Create transitions to junction
        trans_temp = Stateflow.Transition(transMap_handle);
        trans_temp.Source = stepTable_new.StateHandle{ii};
        trans_temp.Destination = juncLine.JunctionHandle;
        trans_temp.LabelString = ['[',transCond,']'];
        trans_temp.SourceOClock = 9;
        src_Point = trans_temp.SourceEndPoint;
        dst_Point = trans_temp.DestinationEndPoint;
        dst_Point(2) = 0;
        trans_temp.DestinationEndPoint = dst_Point;
        mid_Point = [(src_Point(1)+dst_Point(1))/2, 0];
        trans_temp.MidPoint = mid_Point;
        transLine = [stepTable_new.Name(ii), ...
            stepTable_new.Index(ii), ...
            {['[',transCond,']']}, ...
            {''}, ...
            {trans_temp}, ...
            {''}, ...
            {juncLine.Name}];
        transTable_new = [transTable_new; transLine];

    end

    % Update cursor position
    xc = xc+width+dw;

    if ii < size(stepTable_new,1) && stepTable_new.Hierarchy(ii) > stepTable_new.Hierarchy(ii+1)
        diffHier = stepTable_new.Hierarchy(ii)-stepTable_new.Hierarchy(ii+1);
        xc = xc+dw*diffHier;
    end

end

%% Create the transitions

% Add the proper transitions
for ii  = 1:size(transTable,1)
    transLine = transTable(ii,:);

    trans_temp = Stateflow.Transition(transMap_handle);
    trans_temp.Source = stepTable_new.StateHandle{strcmp(stepTable_new.Name,transLine.Step)};
    trans_temp.Destination = stepTable_new.StateHandle{strcmp(stepTable_new.Name,transLine.NextStep)};
    trans_temp.LabelString = ['[', transLine.Condition{1}, ']'];
    trans_temp.SourceOClock = 3;
    src_Point = trans_temp.SourceEndPoint;
    dst_Point = trans_temp.DestinationEndPoint;
    dst_Point(2) = 0;
    trans_temp.DestinationEndPoint = dst_Point;
    mid_Point = [(src_Point(1)+dst_Point(1))/2, 0];
    trans_temp.MidPoint = mid_Point;

    transTable_new = [transTable_new; [table2cell(transLine),{trans_temp},{''},{''}]];
end

%% Add the symbols

% Get model signals used in the test assessment block
inputTA = sltest.testsequence.findSymbol(blockPath, 'Scope', 'Input');

% Input symbols
input = cell(length(inputTA),1);
for ii = 1:length(inputTA)
    input_temp = Stateflow.Data(transMap_handle);
    input_temp.Name = inputTA{ii};
    input_temp.Scope = 'Input';
    input(ii) = {input_temp};
end

% Parameter symbols
paramTA = sltest.testsequence.findSymbol(blockPath, 'Scope', 'Parameter');
param = cell(length(paramTA),1);
for ii = 1:length(paramTA)
    if strcmp(paramTA{ii},'Active_Scenario_Index')
        continue
    end
    param_temp = Stateflow.Data(transMap_handle);
    param_temp.Name = paramTA{ii};
    param_temp.Scope = 'Parameter';
    param(ii) = {param_temp};
end

% Output symbols
output = cell(size(fitTable,1),1);
for ii = 1:size(fitTable,1)
    output_temp = Stateflow.Data(transMap_handle);
    output_temp.Name = fitTable.Name{ii};
    output_temp.Scope = 'Output';
    output(ii) = {output_temp};
end

%% Add min, delay and outport block for fitness signal

% Add min block
add_block('simulink/Math Operations/MinMax',[modelname, '/', min_name])
set_param([modelname, '/', min_name],'Inputs',num2str(verifyCount+1));

% Add delay block
add_block('simulink/Discrete/Delay',[modelname, '/', delay_name])
set_param([modelname, '/', delay_name],'DelayLength','1');
set_param([modelname, '/', delay_name],'InitialCondition','Inf');
set_param([modelname, '/', delay_name],'Orientation','left');

% Add outport
add_block('simulink/Commonly Used Blocks/Out1',[modelname,'/',outport_name])

% Link input signals to Chart
lines_param = get_param(blockPath,'LineHandles');
lines_handle = lines_param.Inport;

port_name_TA = get_param(blockPath,'Blocks');
port_name_TA = port_name_TA(~contains(port_name_TA,' '));

if length(port_name_TA) ~= length(inputTA)
    error('The number of Input symbol in the Test Assessment block does not match the number of ports on the block. Please remove any output signal from the Test Assessment block.')
end

for ii = 1:length(lines_handle)
    
    src_block_handle = get_param(lines_handle(ii),'SrcBlockHandle');
    src_block_name = get_param(src_block_handle,'Name');

    src_port_handle = get_param(lines_handle(ii),'SrcPortHandle');
    src_port_number = get_param(src_port_handle,'PortNumber');

    dest_port_number = find(strcmp(inputTA,port_name_TA{ii}),1);
    add_line(modelname,[src_block_name,'/',num2str(src_port_number)],[transMap_name,'/',num2str(dest_port_number)])
end

% Link Chart to min block
for ii = 1:verifyCount
    add_line(modelname,[transMap_name,'/',num2str(ii)],[min_name,'/',num2str(ii)])
end

% Link min block to delay
add_line(modelname,[min_name,'/1'],[delay_name,'/1'])

% Link delay to min block (last gate)
add_line(modelname,[delay_name,'/1'],[min_name,'/',num2str(verifyCount+1)])

% Link min block to outport
add_line(modelname,[min_name,'/1'],[outport_name,'/1'])

end