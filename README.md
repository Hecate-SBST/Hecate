# Hecate
Hecate is a testing approach for Simulink models using the Test Sequence and Test Assessment blocks. It relies on information provided by the Test Sequence and Test Assessment blocks to guide the search procedure towards falsification of given requirements.

The details of the underlying algorithm are described in the following paper:

> F. Formica, T. Fan, A. Rajhans, V. Pantelic, M. Lawford and C. Menghi, "Simulation-based Testing of Simulink Models with Test Sequence and Test Assessment Blocks," in IEEE Transactions on Software Engineering, doi: 10.1109/TSE.2023.3343753.

For the Models and Results presented in the paper above, check the branch `TSE23`.

The main content in this repository are:
 
* `src`: it contains the functions needed to run Hecate.
* `Tutorial`: it contains a Simulink model and a script to run Hecate on it. The script details some information on the input parameters to the function.

**Note**: Hecate relies on S-Taliro for its search algorithms. Make sure to read the Installation instructions and download S-Taliro.

## Requirements
Hecate requires to have Matlab installed together with some add-ons. In particular:

* Matlab version r2022b or newer (older versions of Matlab have not been tested, but may still work).
* Simulink
* Signal Processing Toolbox
* Simulink Test

## How to install
To run this tool, it is necessary to download S-Taliro from the following link: https://app.assembla.com/spaces/s-taliro_public/subversion/source/HEAD/trunk

To properly install Hecate make sure to follow these steps:

1. Clone this repository.
2. Download S-Taliro from the link above.
3. Unzip the folder, rename it `staliro` (optional), and put it inside this repo at the top level (together with `src` and `Tutorial`).
4. Open Matlab and add to the path `src`.
5. Run the function `updateStaliro` by providing the folder name containing S-Taliro.  
E.g.:	`updateStaliro('./staliro');`
6. Hecate should now be installed successfully. Try to run the Tutorial to check if everything is working properly. 

**Note:** This operation must be performed only once, after downloading S-Taliro for the first time.

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
* *Claudio Menghi*, University of Bergamo, Italy and McMaster University, Canada
