% Class definition for RGDA_Taliro parameters
%
% rgda_params = RGDA_Taliro_parameters
%
% The above code sets the default parameters in the object rgda_params.
%
% Default parameter values:
%
% n_tests = 1000        
%       Number of iterations
% optimization_solver = 'SA_Taliro'
%       Sets the optimization solver for the SDA taliro once a initial
%       sample and search direction is set.
% ld_params = ld_parameters; 
%       Local descent parameters see ld_parameters 
%
% To change the default values to user-specified values use the default
% object already created to specify the properties.
%
% See also: SA_Taliro, staliro_options, ld_parameters
% (C) 2015, Bardh Hoxha, Arizona State University

classdef RGDA_Taliro_parameters

    properties
        optimization_solver = 'SA_Taliro';
        optimization_params = SA_Taliro_parameters;
        plot = 1; 
        
    end
    
    methods        
        function obj = RGDA_Taliro_parameters(varargin)
            if nargin>0
                error(' rgda_parameters : Please access directly the properties of the object.')
            end
        end
    end
end

        