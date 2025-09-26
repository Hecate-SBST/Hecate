function [reqTable, symbTable, assTable] = buildFitnessFunction(modelName,tablesPath)

%% Find table object
 
% Define model name
%modelName = "HecateCruiseControl";

% Load model (if not already loaded)
modelListTemp = get_param(Simulink.allBlockDiagrams('model'),'Name');
if ~any(strcmp(modelName,modelListTemp))
    load_system(modelName)
end

% Define requirement Tables
tables_Temp = slreq.modeling.find(modelName);
Table = tables_Temp(strcmp({tables_Temp.Path},tablesPath));

% Clear temporary variables
clear('*Temp')

%% Read symbols (!!!)

% Read symbols from Requirement Table
symbTemp = findSymbol(Table);

% Store symbol information in a Table object
symbTable = table('Size',[length(symbTemp),7],'VariableTypes',{'string','string','string','string','string','string','logical'}, ...
    'VariableNames',{'Name','Scope','Size','Type','InitialValue','Complexity','IsDesignOutput'});
if ~isempty(symbTemp)
    fieldTemp = string(fieldnames(symbTemp(1)));
    % Loop over symbols
    for ii = 1:length(symbTemp)
        % Loop over symbol field names
        for jj = 1:length(fieldTemp)
            if strcmp(fieldTemp(jj),"IsDesignOutput")
                symbTable.(fieldTemp(jj))(ii) = ~(isempty(symbTemp(ii).IsDesignOutput));
            else
                symbTable.(fieldTemp(jj))(ii) = symbTemp(ii).(fieldTemp(jj));
            end 
        end
    end
end

% Clear temporary variables
clear('*Temp')

%% Read assumptions

% Read root assumptions
assTable_Temp = getAssumptionRows(Table);

% Loop over all assumptions
count = 1;
while count <= length(assTable_Temp)
    assTemp = getChildren(assTable_Temp(count));
    assTable_Temp = [assTable_Temp, assTemp];
    count = count+1;
end

% Create table for assumptions
assTable = table('Size',[length(assTable_Temp),5],'VariableTypes',{'string','string','string','string','string'}, ...
    'VariableNames',{'AssID','Name','PreCond','PostCond','Parent'});

% Loop over assumptions to fill the table
for ii = 1:length(assTable_Temp)

    % Fill in basic information
    assTable.AssID(ii) = assTable_Temp(ii).Index;
    assTable.Name(ii) = assTable_Temp(ii).Summary;
    assTable.PreCond(ii) = assTable_Temp(ii).Preconditions{1};
    assTable.PostCond(ii) = assTable_Temp(ii).Postconditions{1};
    
    % Find parent assumption (if any)
    strTemp = split(assTable_Temp(ii).Index,".");
    if length(strTemp) > 1
        assTable.Parent(ii) = join(strTemp(1:end-1),".");
    else
        assTable.Parent(ii) = "";
    end

end

% Clear temporary variables
clear('*Temp')

%% Read requirements

% Read root requirements
reqTable_Temp = getRequirementRows(Table);

% Loop over all requirements to read children
count = 1;
while count <= length(reqTable_Temp)
    reqTemp = getChildren(reqTable_Temp(count));
    reqTable_Temp = [reqTable_Temp, reqTemp];
    count = count+1;
end

% Create table for requirements
reqTable = table('Size',[length(reqTable_Temp),8],'VariableTypes',{'string','string','string','string','string','string','string', 'string'}, ...
    'VariableNames',{'ReqID','Name','PreCond','PostCond','Duration','Action','Parent', 'RobustFcn'});

% Start counter for requirement rows
ci = 1;     % ci = counter i

% Loop over requirements to fill the table
while ci <= height(reqTable)

    % Skip requirement if it's summary contains the keyword "Hecate_Completeness"
    if contains(reqTable_Temp(ci).Summary,"Hecate_Completeness","IgnoreCase",true)
        reqTable(ci,:) = [];
        reqTable_Temp(ci) = [];
        continue
    end

    % Fill in basic information
    reqTable.ReqID(ci) = reqTable_Temp(ci).Index;
    reqTable.Name(ci) = reqTable_Temp(ci).Summary;
    reqTable.Duration(ci) = reqTable_Temp(ci).Duration;

    % Find parent requirement (if any)
    strTemp = split(reqTable_Temp(ci).Index,".");
    if length(strTemp) > 1
        reqTable.Parent(ci) = join(strTemp(1:end-1),".");
    else
        reqTable.Parent(ci) = "";
    end
    
    % Read precondtions
    preconditions = processHeaders(reqTable_Temp(ci).Preconditions, Table.RequirementHeaders.Preconditions);
    preconditions = preconditions(~strcmp(preconditions,"()"));

        % Join preconditions
    if isempty(preconditions)
        reqTable.PreCond(ci) = "(true)";
    else
        reqTable.PreCond(ci) = join(preconditions, ' && ');
    end
    
    % Read postconditions
    postconditions = processHeaders(reqTable_Temp(ci).Postconditions, Table.RequirementHeaders.Postconditions);
    postconditions = postconditions(~strcmp(postconditions,'()'));
    reqTable.PostCond(ci) = join(postconditions,' && ');

    % Read actions
    actions = processHeaders(reqTable_Temp(ci).Actions, Table.RequirementHeaders.Actions);
    for jj = 1:length(actions)
        if startsWith(actions{jj},'(') && endsWith(actions{jj},')')
            actions{jj} = actions{jj}(2:end-1);
        end
    end
    actions = actions(~strcmp(actions,""));
    if isempty(actions)
        reqTable.Action(ci) = "";
    else
        reqTable.Action(ci) = join(actions, ";"+newline) + ";";
        while contains(reqTable.Action(ci),";;")
            reqTable.Action(ci) = replace(reqTable.Action(ci),";;",";");
        end
    end

    % Increase counter
    ci = ci+1;

end

% Clear temporary variables
clear('*Temp')

%% Robustness Function

for ii = 1:height(reqTable) 
    expression = buildExpressionTree(reqTable.PostCond(ii));
    reqTable.RobustFcn(ii) = expression;
end

stateflow_gen(assTable, modelName, reqTable, symbTable, tablesPath);

end