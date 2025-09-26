% Class definition for the Heacte options, which inherit the properties of
% staliro_options.
%
% opt = hecate_options;
%
% The above function call sets the default values for the class properties.
% For a detailed description of each property open the file
% "HecateFunctions/hecate_options.m" and search for the property name.
%
% To change the default values to user-specified values use the default
% object already created to specify the properties.
%
% E.g.: to change the coefficient of robustness opt.coeffRob = 0.4;
%
% NOTE: For more information on properties, click on them.

% (C) 2025, Federico Formica, McMaster University

classdef hecate_options < staliro_options

    properties
        % Set the Test Sequence scenario name for simulation.
        %
        %   Default option: sequence_scenario = '';
        %
        %   This option chooses the Scenario to be used for input
        %   generation.
        %   If the Test Sequence has the Scenario mode enabled, this option
        %   should contain the name of the scenario to use. If this option
        %   is left empty, then Hecate uses the currently active scenario.
        %   If the Test Sequence does not have the Scenario mode enabled,
        %   then this option must be an empty char array (i.e., '')
        sequence_scenario = '';

        % Set the Test Assessment scenario name for simulation.
        %
        %   Default option: assessment_scenario = '';
        %
        %   This option chooses the Scenario to be used for requirement
        %   specification.
        %   If the Test Assessment has the Scenario mode enabled, this
        %   option should contain the name of the scenario to use. If this
        %   option is left empty, then Hecate uses the currently active
        %   scenario.
        %   If the Test Assessment does not have the Scenario mode enabled,
        %   then this option must be an empty char array (i.e., '')
        assessment_scenario = '';

        % Choose whether to display the performance parameters at the end
        % of the execution.
        %
        %   Default option: disp_results = 0;
        %
        %   This option specifies whether Hecate displays the performance
        %   parameters at the end of the execution (ARCH23 parameters).
        %   The parameters are the following:
        %   - Success Rate (SR): Percentage of runs over the total in which
        %   the tool finds a Failure-Revealing test case.
        %   - Average and Median number of iterations to find the
        %   Failure-Revealing test case. Only runs that actually find a
        %   Failure-Revealing test case are considered. If no run finds a
        %   Failure-Revealing test case, then these two parameters are "-".
        %   - Average and Median best robustness found. Only runs that
        %   reached the maximum number of iterations without finding a
        %   Failure-Revealing test case are considered. If all the runs
        %   find a Failure-Revealing test case, then these two parameters
        %   are "-".
        %
        %   If the option "TimeStatsCollect" is True, then the parameters
        %   are also computed:
        %   - Ratio of Simulation time over Total time: Percentage of how
        %   much computational time is occupied to run the Simulink model.
        %   - Average and median computational time to find the
        %   Failure-Revealing test case. Only runs that actually find a
        %   Failure-Revealing test case are considered. If no run finds a
        %   Failure-Revealing test case, then these two parameters are "-".
        disp_results = 0;

        % Choose whether to read the model specification from a Test
        % Assessment or Requirements Table
        %
        %   Default option: spec_source = 'test_assessment';
        %
        %   This option specifies whether Hecate will look for a Test
        %   Assessment block or a Requirements Table block. The model
        %   specification will be read from the given source and used to
        %   create the fitness generator.
        %   The available options are either:
        %   - 'test assessment': for a Test Assessment block.
        %   - 'requirements table': for a Requirements Table block.
        spec_source = 'test_assessment';

    end

end