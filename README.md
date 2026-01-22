<img src="logo_Hecate.png" align="right" width="150px"/>
# Hecate
Hecate is a black-box testing approach for Simulink models.
It uses a Test Sequence block to generate automatically test cases.
The generation process is guided by a fitness function extracted either from a Test Assessment block or a Requirements Table block.
The fitness value represents the degree of satisfaction of the requirements by a specific test case; by minimizing this value, the search process focuses on test cases that are more critical for the requirements.
<br clear="left"/>


The details of the underlying algorithm are described in two following papers:

* For the fitness function extracted from a *Test Assessment* block:

> F. Formica, T. Fan, A. Rajhans, V. Pantelic, M. Lawford, and C. Menghi, "Simulation-based Testing of Simulink Models with Test Sequence and Test Assessment Blocks," in IEEE Transactions on Software Engineering, 2024, doi: [10.1109/TSE.2023.3343753](https://doi.org/10.1109/TSE.2023.3343753).

* For the fitness function extracted from a *Requirements Table* block:

> F. Formica, C. George, S. Rahmatyan, V. Pantelic, M. Lawford, A. Gargantini, and C. Menghi, "Search-based Testing of Simulink Models with Requirements Tables," 2025, pre-print available on arXiv at [https://arxiv.org/abs/2501.05412](https://arxiv.org/abs/2501.05412)

The branch `TSE23` of this repository contains the results for the Test Assessment paper.

The main content in this repository are:
 
* `src`: it contains the functions needed to run Hecate.
* `Tutorial`: it contains a Simulink model and a script to run Hecate on it. The script details some information on the input parameters to the function.
* `staliro`: it contains some functions from the tool [S-Taliro](https://users.fit.cvut.cz/~apelttom/s_taliro.html) which are resused by our tool. Some functions have been customised to work on Hecate, so they work differently from a regular version of S-Taliro.

## Requirements
Hecate requires to have Matlab installed together with some add-ons. In particular:

* Matlab version r2024b or newer (older versions of Matlab have not been tested, but may still work).
* Simulink
* Simulink Test
* Requirements Toolbox (for Requirements Tables)

## How to install
To install Hecate is sufficient to clone this repository.
No additional operations are needed.

To properly use Hecate, make sure that the folders `src` and `staliro` are part of the active path on Matlab.

## How to Run
Hecate can be run using the function `hecate`.  
Use `help hecate` in Matlab to have more details on the function or check the Tutorial examples in `./Tutorial`.
The file `./Tutorial/runTutorialTA.m` contains an example on how to use Hecate with a Test Assessment block, while `./Tutorial/runTutorialRT.m`is for Requirements Tables.

The files `./src/hecate_options.m` and `./staliro/staliro_options.m` contain useful information on the effect of each option and its default value.

The tutorial can be run after adding to the active path the `src` folder, the `Tutorial` folder, and the `staliro` folder with all their subfolders.  
The following code adds to the path the `Tutorial` folder and run the tutorial example for Test Assessment blocks. 
The `src` and `staliro` folder are added automatically by the script.
If you used a different name for the folder containing the S-Taliro installation (not `staliro`), make sure to update the name on line 12 of `runTutorialTA.m` and `runTutorialRT.m`.

```matlab
addpath("Tutorial")
runTutorialTA;
```

# Contributors
The following authors contributed to the creation of Hecate:

* *Federico Formica*, McMaster University, Canada:  
`formicaf at mcmaster dot ca`
* *Tony Fan*, McMaster University, Canada
* *Chris George*, McMaster University, Canada
* *Alessandro Fischetti*, University of Bergamo, Italy
* *Claudio Menghi*, University of Bergamo, Italy and McMaster University, Canada
