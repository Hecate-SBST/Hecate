# Hecate
Hecate is a testing approach for Simulink models using the Test Sequence and Test Assessment blocks. It relies on information provided by the Test Sequence and Test Assessment blocks to guide the search procedure towards falsification of given requirements.

The main tools in this repository are:
 
* Hecate: Our developed tool.  
* TestTranslation: A script comparing the results between Hecate and S-Taliro

## How to install
To run this tool, it is necessary to download S-Taliro from the following link: https://sites.google.com/a/asu.edu/s-taliro/s-taliro/download  

In addition, the following Matlab script must be removed from the S-Taliro folder: `./auxiliary/Compute_Robustness.m`

The folder containing S-Taliro should then be placed in the main folder (at the same level as `TranslationFunctions`) and be renamed `staliro`.
Also delete or remove from path the folders `staliro/benchmarks` and `staliro/demos`, as they can potentially create conflicts with Hecate functions and models.

To properly install S-Taliro make sure to follow these steps:

1. Make sure that one of the Matlab-supported external compilers is available on your machine. Check this link for reference: [Matlab documentation](https://www.mathworks.com/support/requirements/supported-compilers.html) [Last accessed: August 2023].
2. Set `staliro` as your main working directory in Matlab.
3. Run the `setup_staliro.m` function without providing it any argument.
4. Check that at least the installation of the `dp_taliro` package has finished successfully.

**Note:** This operation must be performed only once, after downloading S-Taliro for the first time.

## How to Run
Execute runHecate, runSTaliro, and TestTranslation by providing the corresponding setting file for the model of interest as a character datatype, and the number of runs as an integer. For example, in the MATLAB terminal Hecate and S-TALIRO can be executed for for the AT model for 5 runs by using:
```matlab
runHecate('SettingAT',5);
runSTaliro('SettingAT',5);
```

The testTranslation script can be run using:
```matlab
testTranslation('SettingAT',5);
```

## Models
Contains 17 different demo models prepared for Hecate.

* **AFC**: A controller for air-to-fuel ration in an engine.
* **AT**: Model of a car automatic transmission with gears 1 to 4
* **AT2**: A second variation of Automatic Transmission
* **CC**: Simulation of a system formed by five cars
* **EKF***: Extended Kalman Filter
* **EU**: A model that computes the rotation matrix given a set of Euler angles
* **FS**: Model of a damping system for wing oscillations
* **HEV**: A hybrid electric vehicle
* **HPS**: model of a heat pump system controlling temperature in a room
* **NN**: Neural Network controller of a levitating magnet above an electromagnet
* **NNP**: General neural network predictor with two hidden layers
* **PM**: A model of the controller for a Pacemaker
* **SC**: Dynamic model of a steam condenser
* **ST**: A signal tracker with 3 available tracking modes
* **TL**: A traffic model of a crossroda, simulating traffic lights and cars
* **TUI**: A model that applies Tustin Integrator for flight control
* **WT**: A model of a wind turbine

**Note(*):** The model for EKF cannot be released to the public, so it is missing from the `Model` folder. The `TestResults` folder still contains the results obtained on this model.

## RQ3
Contains files/figures and scripts for research question 3 - Usefulness.

## ShellScripts
Contains shell scripts used for launching test runs on a UNIX based server.

## TestResults
The directory to which Hecate test results are saved. They are saved in a .mat format using the naming format: 
 
	<Tool>_<model>_<date>_<time>.mat
	
The three available tools being Hecate, S-TALIRO, and TestTranslation.

## TranslationFunctions
Functions used by runHecate.m and testTranslation.m


# Authors
The following authors contributed to the creation of Hecate:

* Federico Formica, McMaster University, Canada: `fedformi at mcmaster dot ca`
* Tony Fan, McMaster University, Canada
* Akshay Rajhans, MathWorks, USA
* Vera Pantelic, McMaster University, Canada
* Mark Lawford, McMaster University, Canada
* Claudio Menghi, McMaster University, Canada
