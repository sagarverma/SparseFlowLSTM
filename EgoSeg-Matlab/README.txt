Egoseg-Matlab
-------------
This software package analyses the optical flow grid data that was produced by Vid2OpticalFlowCSV, trains a stack of binary SVM classifiers and then classifies each frame in the test video into one of seven activities.

The input for this package are:
1. CSV files that were created by Vid2OpticalFlowCSV. 
2. EAF files that contain the ground truth data for each sequences.

It is important to keep the .CSV and .EAF file names in sync. We also recommend to keep sync with the .AVI/.MP4 file names. 
For example, If your input is Huji_Yair_part1.MP4, we suggest to create Huji_Yair_Part1.CSV using Vid2OpticalFlowCSV. 
Our matlab code will then look for Huji_Yair_part1.EAF for the ground-truth annotations and later on will create Huji_Yair_part1.MAT.
To sum this point up:
	.MP4/.AVI - Video files.
	.CSV - Optical flow files.
	.EAF - Ground-truth files. 
	.MAT - Preprocessed files that contains all the data from the .CSV and .EAF files. See Step1 in Example.m.


Ground-truth Data Format
------------------------
We borrowed the idea of using the ELAN annotation tool from Fathi et al [1]. 
You can download the ELAN annotation tool from here: https://tla.mpi.nl/tools/tla-tools/elan/
The ground truth .EAF files we are using contain a tier named 'Event' that contains annotations (labels) over the entire sequences.
The labels are selected from a Controlled Vocabulary (CTRL+SHIFT+C in ELAN) that contains all the activities we know how to classify and a few more (which we ignore).


Training & Classifying Activities
---------------------------------
Please open Example.m and update all the paths according to your local directory structure. 

There are 4 steps in Example.m: 
1. Preprocess the .CSV+.EAF files into .MAT files. It makes things faster later on.
2. Load all the .MAT files into memory (careful, you might need a few GBs here!). 
3. Train a bunch of binary SVM classifiers. Each classifier is saved as a .MAT file with a predefined name (do not change the file names, because the next step will fail if you do).
4. Classify ("segment") the video frames by hierarchically stacking the binary classifiers.  The stacked ('best-of-breed') classifier is saved along with the classification results to a .MAT file with an auto-generated file name (exp_result_*.mat). 


Accessing The Classification Result Data
----------------------------------------
To access the final labeling and accuracy information, load the exp_result_*.mat file that was generated in Step 4 and explore the methods and properties of the variable called 'experiment_data'. 

For example, to access the list of sequences that was used to train and test this classifier, see type:
> experiment_data.sequence_names{:}

To access the final labels assigned to each frame of sequence number 3 in the test set type:
> experiment_data.classifiers{1}.result_labels_per_seq{3}

To know which sequences out of experiment_data.sequence_names{} took part in the test set type:
> experiment_data.sequence_names{experiment_data.classifiers{1}.test_ind}




If you are using this code, please cite the following paper:
"Y. Poleg, C. Arora, S. Peleg, Temporal Segmentation of Egocentric Videos, to appear in CVPR, 2014."



References:
[1] Alireza Fathi, Jessica K. Hodgins, James M. Rehg, Social Interactions: A First-Person Perspective, IEEE Computer Society Conference on Computer Vision and Pattern Recognition (CVPR), 2012.