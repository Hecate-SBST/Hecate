# Hecate
Hecate is a testing approach for Simulink models using the Test Sequence and Test Assessment blocks. It relies on information provided by the Test Sequence and Test Assessment blocks to guide the search procedure towards falsification of given requirements.

The details of the underlying algorithm are described in the following paper:

> F. Formica, T. Fan, A. Rajhans, V. Pantelic, M. Lawford and C. Menghi, "Simulation-based Testing of Simulink Models with Test Sequence and Test Assessment Blocks," in IEEE Transactions on Software Engineering, doi: 10.1109/TSE.2023.3343753.

For the Models and Results presented in the paper above, check the branch `TSE23`.

The main content in this repository are:
 
* `src`: it contains the functions needed to run Hecate.
* `Tutorial`: it contains a Simulink model and a script to run Hecate on it. The script details some information on the input parameters to the function.
* `staliro`: it contains some functions from the tool [S-Taliro](https://users.fit.cvut.cz/~apelttom/s_taliro.html) which are resused by our tool. Some functions have been customised to work on Hecate, so they work differently from a stable version of S-Taliro.

## Requirements
Hecate requires to have Matlab installed together with some add-ons. In particular:

* Matlab version r2022b or newer (older versions of Matlab have not been tested, but may still work).
* Simulink
* Simulink Test

## How to install
To install Hecate is sufficient to clone this repository.
No additional operations are needed.

To properly use Hecate, make sure that the folders `src` and `staliro` are part of the active path on Matlab.

## How to Run
Hecate can be run using the function `hecate`.  
Use `help hecate` in Matlab to have more details on the function or check the Tutorial example in `./Tutorial/runTutorial.m` (the model is saved in Matlab 2022.b, so it requires a version equal or higher of Matlab to run).

The files `./src/hecate_options.m` and `./staliro/staliro_options.m` contain useful information on the effect of each option and its default value.

The tutorial can be run after adding to the active path the `src` folder, the `Tutorial` folder, and the `staliro` folder with all its subfolders.  
The following code adds to the path the `Tutorial` folder and run the tutorial example. The `src` and `staliro` folder are added automatically by the script. If you used a different name from `staliro` for the folder containing the S-Taliro installation, make sure to update the name on line 12 of `runTutorial`.

```matlab
addpath("Tutorial")
runTutorial;
```

# Contributors
The following authors contributed to the creation of Hecate:

* *Federico Formica*, McMaster University, Canada:  
`formicaf at mcmaster dot ca`
* *Tony Fan*, McMaster University, Canada
* *Alessandro Fischetti*, University of Bergamo, Italy
* *Claudio Menghi*, University of Bergamo, Italy and McMaster University, Canada
