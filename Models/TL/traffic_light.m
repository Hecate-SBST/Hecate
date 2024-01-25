function traffic_light(block)
    
    setup(block);
    
end


%% setup
function setup(block)
    % Register number of dialog parameters
    block.NumDialogPrms = 1;
    
    % Register number of ports
    block.NumInputPorts  = 1;
    block.NumOutputPorts = 0;
    
    % Setup port properties to be inherited or dynamic
    block.SetPreCompInpPortInfoToDynamic;
    block.SetPreCompOutPortInfoToDynamic;
    
    % Register sample times
    block.SampleTimes = [0 0];
    
    % Set the block simStateCompliance to custom
    block.SimStateCompliance = 'DefaultSimState';
    
    % Register methods
    block.RegBlockMethod('InitializeConditions',    @InitConditions);
    block.RegBlockMethod('PostPropagationSetup',    @DoPostPropSetup);
    block.RegBlockMethod('Update',             @Update);
    
end


%%
function DoPostPropSetup(block)

% Initialize the Dwork vector
block.NumDworks = 1;

% Dwork(1) stores the handle of the Pulse Generator block
block.Dwork(1).Name            = 'BlockHandle';
block.Dwork(1).Dimensions      = 1;
block.Dwork(1).DatatypeID      = 0;      % double
block.Dwork(1).Complexity      = 'Real'; % real
block.Dwork(1).UsedAsDiscState = false;

end

%%
function InitConditions(block)

    blockH = get_param(gcb,'Handle');
    block.Dwork(1).Data = blockH; % store the block handle in the s-function so that we can access it at run time.
     
end

%%
function Update(block)
    
    lb = block.DialogPrm(1).Data;
    u =  block.InputPort(1).Data;
    enumType = class(u);
    [ values, literals ] = enumeration( enumType );
    if( lb ~= u )
        newValueString = sprintf('%s.%s', enumType, literals{ find(values==u) } ); %#ok<FNDSB>
        set_param( block.Dwork(1).Data, 'mode', newValueString );
    end
end