classdef SVMClassifier < handle
    
    
    properties
        %MAX_TRAINING_SAMPLES_PER_CLASS = 12500;
    end
        
    properties
        classmap;
        classnames;
        sequences;
        cfg;
        train_ind;
        test_ind;
        svm_classifier;
        train_success;
        train_accuracy_info;
        test_accuracy_info;
    end
    
    methods
        function obj = SVMClassifier
            obj.classnames = {'defaultname_min1','defaultname_plus1'};
            obj.train_success = 0;
        end
        
        
        function Initialize(obj,sequences,cfg)
            obj.sequences = sequences;
            obj.cfg = cfg;
            
        end
        
        function StripSeqData(obj)
            obj.sequences = {};
        end
        
        
        function success = Train_with_mask(obj,train_seq_ind)
            obj.train_ind = train_seq_ind;
            train_data = [];
            train_labels = [];
            
            for i=1:numel(obj.train_ind)
                cur_seq_labels = obj.ConvertLabels(obj.sequences{obj.train_ind(i)});
                cur_seq_labels = cur_seq_labels .* obj.sequences{obj.train_ind(i)}.Train_mask;
                selected_ind = find(cur_seq_labels~=0);
                train_labels = [train_labels; cur_seq_labels(selected_ind)];
                cur_seq_fv = obj.CreateFeatureVectors(obj.sequences{obj.train_ind(i)},selected_ind);
                train_data = [train_data; cur_seq_fv];
            end
            
            success = obj.DoTrain(train_data,train_labels);
        end
        
        
        function success = DoTrain(obj,train_data,train_labels)
            
            [train_data, train_labels] = obj.CropTrainDataset(train_data,train_labels);
            
            accuracy_info = AccuracyInfo(numel(obj.classnames));
            accuracy_info.SetClassNames(obj.classnames);
            
            % Reset the test accuracy info
            obj.test_accuracy_info = AccuracyInfo(numel(obj.classnames));
            obj.test_accuracy_info.SetClassNames(obj.classnames);
            try
                fprintf('%s Training...\n',log_line_prefix);
                
                svmopt = statset('MaxIter',obj.cfg.get('SVM_MAX_ITER'),'Display','off');
                additional_opts = obj.cfg.get('SVM_ADDITIONAL_OPTS');
                obj.svm_classifier = svmtrain(train_data, train_labels,'kernel_function',obj.cfg.get('SVM_KERNEL'),...
                                                                       'method',obj.cfg.get('SVM_OPT_METHOD'),...
                                                                       'autoscale',obj.cfg.get('SVM_AUTO_SCALE'),...
                                                                       'options',svmopt,additional_opts{:});

                train_res = svmclassify(obj.svm_classifier,train_data);
%                 res_labels = train_res;
%                 num_errs = sum(abs(train_labels-res_labels) ./ 2);
%                 accuracy = (numel(res_labels)-num_errs) / numel(res_labels);
                
%                 fprintf('%s [Train] Accuracy=%.3f   (%d errors over %d frames [%s=%d %s=%d])\n',log_line_prefix,accuracy,num_errs, numel(res_labels),...
%                                                                                   obj.classnames{1},sum(train_labels==-1),...
%                                                                                   obj.classnames{2},sum(train_labels==1));

                cur_exp_confmat = obj.GetConfusionMat(train_labels,train_res);
                accuracy_info.AddExperiment(cur_exp_confmat);

                fprintf('%s [Train] Accuracy: %s\n',log_line_prefix,accuracy_info.GetAccuracyStr());
                fprintf('%s [Train] Number of support vectors: %d\n',log_line_prefix,numel(obj.svm_classifier.SupportVectorIndices));
                
                obj.train_accuracy_info = accuracy_info;
                
                success = 1;
                obj.train_success = 1;
            catch err
                fprintf('%s [Error] Error running experiment. Details: %s.\n',log_line_prefix,err.message);
                success = 0;
            end
        end
        
        function success = Train_with_ind(obj, train_seq_ind)
        
            obj.train_ind = train_seq_ind;
            train_data = [];
            train_labels = [];
            
            for i=1:numel(obj.train_ind)
                cur_seq_labels = obj.ConvertLabels(obj.sequences{obj.train_ind(i)});
                selected_ind = find(cur_seq_labels~=0);
                train_labels = [train_labels; cur_seq_labels(selected_ind)];
                cur_seq_fv = obj.CreateFeatureVectors(obj.sequences{obj.train_ind(i)},selected_ind);
                train_data = [train_data; cur_seq_fv];
            end
            
            success = obj.DoTrain(train_data,train_labels);
        end
               
        function [train_data, train_labels] = CropTrainDataset(obj,train_data,train_labels)
        
            classes = unique(train_labels);
            classes(classes==0) = []; % remove unwanted classes
            for i=1:numel(classes)
                cur_class_ind = find(train_labels==classes(i));
                if (numel(cur_class_ind) > obj.cfg.get('SVM_MAX_TRAINING_SAMPLES_PER_CLASS'))
                    
                    ind_to_remove = cur_class_ind(randperm(numel(cur_class_ind)));
                    ind_to_remove = ind_to_remove(1:(numel(cur_class_ind) - obj.cfg.get('SVM_MAX_TRAINING_SAMPLES_PER_CLASS')));
                    train_labels(ind_to_remove,:) = [];
                    train_data(ind_to_remove,:) = [];
                end
            end
        end
        
        function [res_test_accuracy_info, test_ind] = Test(obj)
            test_ind = setdiff(1:numel(obj.sequences),obj.train_ind);
            obj.test_ind = test_ind;
            
            obj.test_accuracy_info = AccuracyInfo(numel(obj.classnames));
            obj.test_accuracy_info.SetClassNames(obj.classnames);
            
            fprintf('%s Testing...\n',log_line_prefix);
            
            for i=1:numel(test_ind)
                                
                cur_seq = obj.sequences{test_ind(i)};
                
                [~, fname, fname_ext] = fileparts(cur_seq.SequenceName);
                fname = [fname fname_ext];
                
                cur_seq_labels = obj.ConvertLabels(cur_seq);

                mask = cur_seq_labels~=0;
                %selected_ind = find(mask);
                if (sum(mask)==0)
                    % No relevant data in this sequence.
                    fprintf('%s [Test] [%s] No relevant data. Skipping.\n',log_line_prefix,fname);
                    continue;
                end
                
                cur_seq_labels_masked = cur_seq_labels(mask);

                
                [res_labels] = obj.TestSequence(cur_seq,mask);
                
                myasssert(numel(cur_seq_labels_masked) == numel(res_labels));
                
                cur_exp_confmat = obj.GetConfusionMat(cur_seq_labels_masked,res_labels);
                
                accuracy_info = AccuracyInfo(numel(obj.classnames));
                accuracy_info.SetClassNames(obj.classnames);
                accuracy_info.AddExperiment(cur_exp_confmat);
                    
                fprintf('%s [Test] [%s] Sequence Accuracy: %s\n',log_line_prefix,fname,accuracy_info.GetAccuracyStr());
                
                % Collect data for total accuracy..
                obj.test_accuracy_info.AddExperiment(cur_exp_confmat);
            end
            
            res_test_accuracy_info = obj.test_accuracy_info;
            
            fprintf('%s [Test] Current Iteration Test Accuracy (#SV=%d): %s\n',log_line_prefix,numel(obj.svm_classifier.SupportVectorIndices),obj.test_accuracy_info.GetAccuracyStr());
        end

        function [res_labels] = TestSequence(obj, cur_seq, mask)
            
                if obj.train_success==0
                    res_labels = zeros(size(find(mask==1)));
                    return;
                end
                
                cur_seq_fv = obj.CreateFeatureVectors(cur_seq,find(mask==1));

                temp_labels = svmclassify(obj.svm_classifier,cur_seq_fv);
                res_labels = temp_labels;
                %res_labels = zeros(size(mask));
                %res_labels(mask) = temp_labels;
        end
        
        function fv = CreateFeatureVectors(obj,data,ind)
            fv = [data.LK_valid_count_smooth(ind,:), data.Template_response(ind,:), data.Clusters_distance(ind,:)];
        end
        
        function [labels] = ConvertLabels(obj,data)
            labels = zeros(size(data.Labels));
            
            for i=1:size(obj.classmap,1)
                if obj.classmap{i,2}~=0
                    curclass_ind = find(not(cellfun('isempty', strfind(data.Labels,obj.classmap{i,1}))));

                    labels(curclass_ind) = obj.classmap{i,2};
                end
                
            end            
        end
        
        
        function confmat = GetConfusionMat(obj,groundtruth_labels,result_label)
            orderarr = unique(cell2mat(obj.classmap(:,2)));
            orderarr(orderarr==0) = [];
            confmat = confusionmat(groundtruth_labels,result_label,'order',orderarr);
        end
    end
    

end