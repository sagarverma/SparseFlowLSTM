classdef ExperimentManager < handle
   
    properties
        
        CLASS_LABELS = {'Walking'; ...
                        'Driving'; ...
                        'Standing'; ...
                        'Passenger'; ...
                        'Wheels'; ...
                        'Sitting'; ...
                        'Static'};
        
    end
    
    properties
        sequences;
        prev_train_sets;
        experiment_type;
        experiment_cfg;
        experiment_data;
    end
    
    methods        

        % Experiment method - 'rand_iter' or 'fixed'.
        % Experiment type - 'Node-Stationary-Transit'
        %                   'Node-Box-Open'
        %                   'Node-Static-Moving'
        %                   'Node-Sitting-Standing'
        %                   'Node-Walking-Wheels'
        %                   'Node-Driving-Passenger'
        %                   'BestOfBreedMulticlassHierarchy'
        function obj = ExperimentManager(datarep,experiment_type,cfg)
                
            obj.experiment_type = experiment_type;
            obj.experiment_cfg = cfg;
            obj.sequences = datarep.sequences;
            
            obj.experiment_data = ExperimentData(datarep.sequences,experiment_type,cfg);
            
            obj.prev_train_sets = {};
        end
        
        function classifier = ClassifierFactory(obj)

            switch (obj.experiment_type)
                case 'Node-Stationary-Transit'
                    classifier = SVM_L1_StationaryTransit();
                case 'Node-Box-Open'
                    classifier = SVM_L2_BoxOpen();
                case 'Node-Static-Moving'
                    classifier = SVM_L2_StaticMoving();
                case 'Node-Sitting-Standing'
                    classifier = SVM_L3_SittingStanding();
                case 'Node-Walking-Wheels'
                    classifier = SVM_L3_WalkingWheels();
                case 'Node-Driving-Passenger'
                    classifier = SVM_L3_DrivingPassenger();
%                case 'MulticlassShareBoost'
%                    classifier = SVM_MulticlassShareboost();
%                case 'MulticlassLibsvm'
%                    classifier = SVM_MulticlassLibsvm();
%                case 'MulticlassHierarchy'
%                    classifier = SVM_MulticlassHierarchy();
                case 'BestOfBreedMulticlassHierarchy'
                    classifier = SVM_BestOfBreedMulticlassHierarchy();
                otherwise
                    error('Unknown experiment type "%s".',obj.experiment_type);
            end
        end
        
        function exp_data = RunExperiment_MultipleIterations(obj,num_iterations)    
            obj.prev_train_sets = {};
            
            temp_classifier = obj.ClassifierFactory();
%             total_accuracy_info = AccuracyInfo(numel(temp_classifier.classnames));
%             total_accuracy_info.SetClassNames(temp_classifier.classnames);
%             
            if (obj.experiment_cfg.get('RANDOM_TRAINING_SET')==1)
                    data_picker = DataPicker_RandomTrainingSet(obj.sequences);
            else
                    data_picker = DataPicker_FixedTrainingSet(obj.sequences);
            end
                  
            data_picker.Initialize(obj.experiment_cfg);
                  
            i=1;
            total_iter=0;
            while i<=num_iterations
                
                fprintf('%s Experiment %s Iteration #%d - Picking data...',log_line_prefix,obj.experiment_type,i);
                
                if (obj.experiment_cfg.get('EXPERIMENT_DATA_AUTO_DUMP_PER_ITER')==1) 
                    obj.experiment_data = ExperimentData(obj.sequences,obj.experiment_type,obj.experiment_cfg);
                end
                
                pick_retry = 0;
                while pick_retry < 5
                    [train_ind] = data_picker.PickData(temp_classifier);
                    
                    if obj.FindMatchingTrainSet(train_ind) == -1
                        break;
                    end
                    
                    pick_retry = pick_retry + 1;
                    fprintf('.');
                end
                fprintf('\n');
                
                if (pick_retry == 5)
                    fprintf('%s Cant find a unique training set! Breaking at interation #%d!',log_line_prefix,i);
                    break;
                end
                
                obj.prev_train_sets{end+1} = train_ind;
                
                for j=1:numel(train_ind)
                    [~, fname, fname_ext] = fileparts(obj.sequences{train_ind(j)}.SequenceName);
                    fname = [fname fname_ext];
                    fprintf('%s Training Sequence: %s\n',log_line_prefix,fname);
                end
                
                
                [cur_accuracy_info iter_success] = obj.RunExperiment_SingleIteration(train_ind,i);
                 
                if (obj.experiment_cfg.get('EXPERIMENT_DATA_AUTO_DUMP_PER_ITER')==1) 
                    obj.experiment_data.Save();
                end

                
                %total_accuracy_info.AddExperiment(cur_accuracy_info.confmat);
                
                if (iter_success==1)
                    i=i+1;
                end
                
                total_iter = total_iter+1;
                if (total_iter > num_iterations*3)
                    break;
                end
                
                fprintf('\n\n');
                
            end
            

            fprintf('%s Experiment %s Done.\n',log_line_prefix,obj.experiment_type);
            %fprintf('%s Experiment %s Summary: %s\n',log_line_prefix,obj.experiment_type,total_accuracy_info.GetAccuracyStr());
            
            exp_data = obj.experiment_data;
        end
        
        function found_match = FindMatchingTrainSet(obj,train_ind)
            
            found_match = -1;
            
            for i=1:numel(obj.prev_train_sets)
                if isempty(setxor(obj.prev_train_sets{i},train_ind))
                    found_match = i;
                    break;
                end
            end
        end
        
       function [accuracy_info success] = RunExperiment_SingleIteration(obj,train_ind,iterationnum)
            
            if nargin<3
                iterationnum=1;
            end
            
            fprintf('%s Experiment %s Iteration #%d - Creating feature vectors...\n',log_line_prefix,obj.experiment_type,iterationnum);
                
            
            classifier = obj.ClassifierFactory();
            
            classifier.Initialize(obj.sequences,obj.experiment_cfg);
            
            if (obj.experiment_cfg.get('RANDOM_TRAINING_SET')==1)
                success = classifier.Train_with_ind(train_ind);
            else
                success = classifier.Train_with_mask(train_ind);
            end
            
            accuracy_info = AccuracyInfo(numel(classifier.classnames));
            
            if success==0
                fprintf('%s Experiment %s Iteration #%d - Failed training classifier. Skipping.\n',log_line_prefix,obj.experiment_type,iterationnum);
                % test_accuracy info will be dummy ones here..
                obj.experiment_data.AddExperiment(classifier);
                return;
            end
            
            [accuracy_info test_ind] = classifier.Test();
            
            obj.experiment_data.AddExperiment(classifier);
            
            %fprintf('%s Experiment %s Iteration #%d: %s\n',log_line_prefix,obj.experiment_type,iterationnum,accuracy_info.GetAccuracyStr());
        end  
        

    end
    
    
    
    
end