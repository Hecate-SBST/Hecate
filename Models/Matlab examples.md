# Matlab examples

1. Test Sequence Basics: https://www.mathworks.com/help/sltest/ug/introduction-to-test-sequences.html  
**Notes**: Very similar to AT benchmark (it can be the same model), there are two possible pair of Test Sequence and Assessment (both testing only the shift controller, not the whole model).  
Block Count: 74

2. Use Test Sequence Scenarios in the Test Sequence Editor and Test Manager: https://www.mathworks.com/help/sltest/ug/define-test-sequence-scenarios-in-test-sequence-editor.html  
**Notes**: It has a pair of Test Sequence - Test Assessment blocks that test only the controller (and not the plant model).  
Block Count: 26

3. Assess a Model by Using When Decomposition: https://www.mathworks.com/help/sltest/ug/using-when-decomposition-to-write-tests.html  
**Notes**: It has both Test Sequence and Test Assessment, and it tests the whole model (a bit simple though).  
Block Count: 29

4. Assess the Damping Ratio of a Flutter Suppression System: https://www.mathworks.com/help/sltest/ug/assess-damping-ratio-of-flutter-suppression-system.html  
**Notes**: It uses the Test Manager to try different combinations of the inputs. It may be possible to write an equivalent pair of Test Sequence (4 values respectively of Mach Speed and Altitude are given in `Iterations`, so the system tests the 16 combinations) and Test Assessment (`Custom Criteria`) blocks.  
Block Count: 245  
Requires:
	- Curve Fitting Toolbox  
	- Aerospace Blockset
	- Aerospace Toolbox
	- Simscape
	- Simscape Multibody

5. Test Traffic Light Control by Using Logical and Temporal Assessments: https://www.mathworks.com/help/sltest/ug/test-traffic-light-using-logical-and-temporal-assessments.html  
**Notes**: It uses the Test Manager. It should be possible to extract a Test Assessment (`Logical and Temporal Assessments`), but there is no input to the model. We would need to change the model to introduce a Test Sequence.  
Block Count: 63