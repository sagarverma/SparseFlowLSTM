
%% Step1 - NO NEED TO RUN THIS STEP MORE THAN ONCE. IT SERIALIZES THE RESULT.
%         Preprocess all the sequences in the dataset.  
%         This function will read all the CSV files produces by
%         Vid2OpticalFlowCSV, process them and create .mat files with
%         corresponding feature vectors. We want to add a suffix to the .mat
%         files so we pass that as empty string. We use a predefined
%         labelmap to remap activities such as 'eating' to 'sitting' and
%         etc.
Util.PrepreocessSequences('../../dataset/EgoOutside/csvs_32x32/*.csv','','');


%% Step 2 - Create a data repository containing all the processed data from the previous step.

clear datarep; 
% We didn't add a suffix in the previous step, so again passing an empty
% string here.
datarep = DataRepository('');
% Add all sequences to the data repository. Note that while we are passing
% '*.csv' as an argument, what is actually getting loaded in the *.mat
% that correspond to these CSV (these were created in the previous step).
datarep.AddSequences({  '../../dataset/EgoOutside/csvs_32x32/*.csv'});

% Optional: save the data repository for later use.
%save('svm_test_datarep.mat','datarep');

%% Step 3 - Train binary classifiers seperately and save them.
clear EM; 
clear cfg;


cfg = ConfigWrapper();

EM = ExperimentManager(datarep,'Node-Stationary-Transit',cfg);
ED = EM.RunExperiment_MultipleIterations(20);
ED.Save('Node-Stationary-Transit');
clear EM ED;

EM = ExperimentManager(datarep,'Node-Box-Open',cfg);
ED = EM.RunExperiment_MultipleIterations(20);
ED.Save('Node-Box-Open');
clear EM ED;

EM = ExperimentManager(datarep,'Node-Static-Moving',cfg);
ED = EM.RunExperiment_MultipleIterations(20);
ED.Save('Node-Static-Moving');
clear EM ED;

cfg = ConfigWrapper({'SVM_KERNEL','rbf'; 
                    'SVM_MAX_TRAINING_SAMPLES_PER_CLASS',   50000;
                    'PICKER_MIN_LABELS_PER_CLASS', 100000});
clear EM ED;
EM = ExperimentManager(datarep,'Node-Sitting-Standing',cfg);
ED = EM.RunExperiment_MultipleIterations(20);
ED.Save('Node-Sitting-Standing');
clear EM ED;

EM = ExperimentManager(datarep,'Node-Walking-Wheels',cfg);
ED = EM.RunExperiment_MultipleIterations(20);
ED.Save('Node-Walking-Wheels');
clear EM ED;


EM = ExperimentManager(datarep,'Node-Driving-Passenger',cfg);
ED = EM.RunExperiment_MultipleIterations(20);
ED.Save('Node-Driving-Passenger');
clear EM ED;




%% Step 4 - Evaluate the overwhole accuracy of the stacked binary classifiers
clear EM ED cfg;
cfg = ConfigWrapper();
EM = ExperimentManager(datarep,'BestOfBreedMulticlassHierarchy',cfg);
ED = EM.RunExperiment_MultipleIterations(1);
ED.Save();
