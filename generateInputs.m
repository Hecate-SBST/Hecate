function xIn = generateInputs(reqID,t,paramName,paramValue)

% Create Hecate variables
for ii = 1:length(paramName)
    eval(paramName(ii) + " = " + paramValue(ii) + ";")
end

% Switch statement
switch reqID
    case "AFC"
        xIn = zeros(length(t),2);

        % Pedal_Angle
        xIn(t <= 11,1) = Hecate_throttle1;
        xIn(t > 11 & t <= 12 + Hecate_delay1,1) = Hecate_throttle2;
        xIn(t > 12 + Hecate_delay1,1) = Hecate_throttle3;

        % Engine_Speed
        xIn(:,2) = Hecate_RPM;

    case "AT"
        xIn = zeros(length(t),2);

        % Throttle
        xIn(t <= 10,1) = Hecate_param1;
        xIn(t > 10,1) = Hecate_param3;

        % Brake
        xIn(t <= 10,2) = Hecate_param2;
        xIn(t > 10,2) = Hecate_param4;

    case "AT2"
        xIn = zeros(length(t),2);

        % Throttle
        xIn(t <= 20,1) = 50+Hecate_Param1;
        xIn(t > 20,1) = 50+Hecate_Param3;

        % Brake
        xIn(t <= 20,2) = 50+Hecate_Param2;
        xIn(t > 20,2) = 50+Hecate_Param4;

    case "CC"
        xIn = zeros(length(t),2);

        % Throttle
        xIn(:,1) = 0.5+Hecate_brake2*cos(2*pi*Hecate_freq*t);
        xIn(t <= Hecate_trigger,1) = Hecate_throttle1;

        % Brake
        xIn(:,2) = Hecate_brake1;

    case "EKF"
        xIn = zeros(length(t),1);

        % Temperature
        xIn(t < 3333,1) = Hecate_temp1+55;
        xIn(t >= 3333 & t < 6666,1) = Hecate_temp2+55;
        xIn(t >= 6666,1) = Hecate_temp3+55;

    case "EU"
        xIn = zeros(length(t),6);

        % Angle phi
        phiTemp = pi*Hecate_phiRamp*t;
        xIn(:,1) = mod(phiTemp,2*pi);

        % Angle theta
        thetaTemp = pi/2+pi/2*sin(t*Hecate_thetaFreq);
        xIn(:,2) = mod(thetaTemp,pi);

        % Angle psi
        psiTemp = -pi/3+pi*(t >= Hecate_psiDelay);
        xIn(:,3) = mod(psiTemp,2*pi);

        % Vector components
        xIn(:,4) = Hecate_VectX;
        xIn(:,5) = Hecate_VectY;
        xIn(:,6) = Hecate_VectZ;

        % Remove temp variables
        clear('*Temp')

    case "FS"
        xIn = zeros(length(t),2);

        % Mach number
        xIn(:,1) = Hecate_Mach;

        % Altitude
        xIn(:,2) = Hecate_Alt;

    case "HPS"
        xIn = zeros(length(t),2);

        % Set temperature
        xIn(:,1) = Hecate_Tset;

        % Outside temperature
        xIn(:,2) = Hecate_Tout;

    case "NN"
        xIn = zeros(length(t),1);

        % Reference position
        xIn(:,1) = 2+Hecate_Amp2*sin(2*pi*Hecate_Freq2*t);
        xIn(t <= 1.5+Hecate_Delay1,1) = Hecate_Step1;

    case "NNP"
        xIn = zeros(length(t),2);

        % First signal
        xIn(t < 50,1) = Hecate_RangeX;
        xIn(t >= 50,1) = Hecate_RangeX2;

        % Second signal
        xIn(t < 50,2) = Hecate_RangeY;
        xIn(t >= 50,2) = Hecate_RangeY2;

    case "PM"
        xIn = zeros(length(t),3);

        % Mode
        xIn(:,1) = round(Hecate_Mode);

        % Ventricle heartbeat detect
        xIn(:,2) = 0;

        % Atrium heartbeat detect
        xIn(:,3) = 0;

        T_node = 0;
        while T_node < t(end)
            T_start = T_node + 2 + Hecate_delayOn;
            T_end = T_start + 0.05 + Hecate_delayOff;
            xIn(t >= T_start & t < T_end,3) = 1;
            T_node = T_end;
        end

        xIn(t >= Hecate_HeartFail,3) = 0;

    case "PM1"
        xIn = zeros(length(t),1);

        % Heart rate
        xIn(:,1) = pchip(0:25:100,[Hecate_lrl1, Hecate_lrl2, Hecate_lrl3, Hecate_lrl4, Hecate_lrl5],t);

    case "PM2"
        xIn = zeros(length(t),2);

        % Ventricle voltage signal
        xIn(:,1) = pchip([0, 7.5, 15],[Hecate_Amp1, Hecate_Amp2, Hecate_Amp3],t);

        % Mode
        xIn(t < 7.5,2) = 2;
        xIn(t >= 7.5,2) = floor(Hecate_Mode2);

    case "SC"
        xIn = zeros(length(t),1);

        % Steam flow rate
        xIn(:,1) = 4+Hecate_Amp*sin(2*pi*Hecate_Freq*t);
        xIn(t <= Hecate_delay,1) = Hecate_flow1;

    case "ST"
        xIn = zeros(length(t),2);

        % Signal
        xIn(t < 3*Hecate_Phase1,1) = Hecate_Amp1 * sin(2*pi*Hecate_Freq1*t(t < 3*Hecate_Phase1));
        T_node = 3*Hecate_Phase1;
        while T_node < t(end)
            T_half = T_node + 1/2/Hecate_Freq2;
            xIn(t >= T_node & t < T_half,1) = interp1([T_node, T_half],Hecate_Amp2*[-1,1],t(t >= T_node & t < T_half));
            T_node = T_half + 1/2/Hecate_Freq2;
            xIn(t >= T_half & t < T_node,1) = interp1([T_half, T_node],Hecate_Amp2*[1,-1],t(t >= T_half & t < T_node));
        end

        % Mode
        xIn(t < Hecate_Phase1,2) = 0;
        xIn(t >= Hecate_Phase1 & t < 2*Hecate_Phase1,2) = 1;
        xIn(t >= 2*Hecate_Phase1 & t < 3*Hecate_Phase1,2) = 2;
        xIn(t >= 3*Hecate_Phase1 & t < 2*Hecate_Phase1+10,2) = 0;
        xIn(t >= 2*Hecate_Phase1+10 & t < Hecate_Phase1+20,2) = 1;
        xIn(t >= Hecate_Phase1+20,2) = 2;

    case "TL"
        xIn = zeros(length(t),2);

        % Cars at traffic light 1
        xTemp = Hecate_Amp1*sin(2*pi*Hecate_Freq1*t);
        xTemp = round(xTemp);
        xTemp(xTemp > 5) = 5;
        xTemp(xTemp < 0) = 0;
        xIn(:,1) = xTemp;

        % Cars at traffic light 2
        yTemp = Hecate_Amp2*sin(2*pi*Hecate_Freq2*(t+Hecate_delay));
        yTemp = round(yTemp);
        yTemp(yTemp > 5) = 5;
        yTemp(yTemp < 0) = 0;
        xIn(:,2) = yTemp;

    case "TUI"
        xIn = zeros(length(t),2);

        % Input signal
        xIn(t < 10,1) = 0.5+Hecate_Amp;
        xIn(t >= 10,1) = 0.5+Hecate_Freq;

        % Reset
        xIn(:,2) = 0;

    case "WT"
        xIn = zeros(length(t),2);

        % Wind speed
        windTemp = Hecate_mean2+Hecate_amp2*sin(2*pi/Hecate_freq2*t);
        windTemp(t < 300) = Hecate_wind1;
        windTemp(windTemp > 16) = 16;
        windTemp(windTemp < 8) = 8;
        xIn(:,1) = windTemp;

    otherwise
        error("The requirement ID given is not in the list of available ones.")
end

end