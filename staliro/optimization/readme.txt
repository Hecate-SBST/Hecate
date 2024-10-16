This folder includes customized optimization algorithms for S-Taliro and 
wrappers for general purpose optimization algorithms.

OPTIMIZATION ALGORITHM

An optimization algorithm should be implemented in an m-file with the 
following interface:

[run, history] = OptimizationAlgo(inpRanges, opt)

where:

 INPUTS:

   inpRanges: n-by-2 lower and upper bounds on initial conditions and
       input ranges, e.g.,
           inpRanges(i,1) <= x(i) <= inpRanges(i,2)
       where n = dimension of the initial conditions vector +
           the dimension of the input signal vector * # of control points

   opt : staliro_options object
        See the option search_space_constrained for adding and using 
        general convex constraints (in addition to the hyperbox constraints 
        in inpRanges).

 OUTPUTS:
   run: a structure array that contains the results of each run of
       the stochastic optimization algorithm. The structure has the
       following fields:

           bestRob : The best (min or max) robustness value found

           bestSample : The sample in the search space that generated
               the trace with the best robustness value.

           nTests: number of tests performed (this is needed if
               falsification rather than optimization is performed)

           bestCost: Best cost value. bestCost and bestRob are the
               same for falsification problems. bestCost and bestRob
               are different for parameter estimation problems. The
               best robustness found is always stored in bestRob.

           paramVal: Best parameter value. This is used only in
               parameter query problems. This is valid if only if
               bestRob is negative.

           falsified: Indicates whether a falsification occurred. This
               is used if a stochastic optimization algorithm does not
               return the minimum robustness value found.

           time: The total running time of each run. This value is set by
               the calling function.

   history: array of structures containing the following fields

       rob: all the robustness values computed for each test

       samples: all the samples generated for each test

       cost: all the cost function values computed for each test.
           This is the same with robustness values only in the case
           of falsification.
		   
For calling and using the robustness computation engine or the custom cost 
function see Compute_Robustness.m.
		
OPTIMIZATION ALGORITHM OPTIONS

The m-file OptimizationAlgo must be accompanied by a class for setting 
the options for the algorithm. The naming convention should be:

	OptimizationAlgo_parameters

The only required property is n_tests which sets the maximum number of 
tests that must be performed by the optimization algorithm.

See UR_Taliro_parameters.m for an example and template.
			
				   