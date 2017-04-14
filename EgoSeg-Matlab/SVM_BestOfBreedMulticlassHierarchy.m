classdef SVM_BestOfBreedMulticlassHierarchy < SVMClassifier

    properties
       classifier_tree; 
       result_labels_per_seq;
    end
    
    methods
        function obj = SVM_BestOfBreedMulticlassHierarchy()
            obj.classmap = {'Walking',1; ...
                        'Driving',2; ...
                        'Standing',3; ...
                        'Passenger',4;
                        'Wheels',5;
                        'Sitting',6;
                        'Static',7};
                    
            obj.classnames = {'Walking','Driving','Standing','Passenger','Wheels','Sitting','Static'};            
            
            pretrained_classifiers_names = {'Node-Walking-Wheels','Node-Driving-Passenger','Node-Box-Open','Node-Sitting-Standing',...
                                            'Node-Static-Moving','Node-Stationary-Transit'};

            missing_classifiers = {};
            
            for i=1:numel(pretrained_classifiers_names)
                if ~exist([pretrained_classifiers_names{i} '.mat'],'file')
                    missing_classifiers{end+1} = pretrained_classifiers_names{i};
                end
            end
            
            if numel(missing_classifiers)>0
                required_files_str = []
                for i=1:numel(pretrained_classifiers_names)
                    required_files_str = [required_files_str pretrained_classifiers_names{i} '.mat,'];
                end
                required_files_str = required_files_str(1:end-1);
                
                missing_files_str = []
                for i=1:numel(missing_classifiers)
                    missing_files_str = [missing_files_str missing_classifiers{i} '.mat,'];
                end
                missing_files_str = missing_files_str(1:end-1);
                
                error('SVM_BestOfBreedMulticlassHierarchy requires the following pretrained classifier files to be present:\n%s\nCouldnt find the following pretrained classifiers:\n%s',required_files_str,missing_files_str);
            end
            
            ED_reload = ExperimentData.Load('Node-Stationary-Transit');
            c_ind = ED_reload.GetBestClassifierIndByAccuracy();
            obj.classifier_tree = TreeNode(ED_reload.classifiers{c_ind}); 
            
            ED_reload = ExperimentData.Load('Node-Static-Moving');
            c_ind = ED_reload.GetBestClassifierIndByAccuracy();
            obj.classifier_tree.FirstChild = TreeNode(ED_reload.classifiers{c_ind});
            
            ED_reload = ExperimentData.Load('Node-Sitting-Standing');
            c_ind = ED_reload.GetBestClassifierIndByAccuracy();
            obj.classifier_tree.FirstChild.SecondChild = TreeNode(ED_reload.classifiers{c_ind}); 
            
            ED_reload = ExperimentData.Load('Node-Box-Open');
            c_ind = ED_reload.GetBestClassifierIndByAccuracy();
            obj.classifier_tree.SecondChild = TreeNode(ED_reload.classifiers{c_ind}); 
            
            ED_reload = ExperimentData.Load('Node-Driving-Passenger');
            c_ind = ED_reload.GetBestClassifierIndByAccuracy();
            obj.classifier_tree.SecondChild.FirstChild = TreeNode(ED_reload.classifiers{c_ind});
            
            ED_reload = ExperimentData.Load('Node-Walking-Wheels');
            c_ind = ED_reload.GetBestClassifierIndByAccuracy();
            obj.classifier_tree.SecondChild.SecondChild = TreeNode(ED_reload.classifiers{c_ind});
        end

        function Initialize(obj,sequences,cfg)
            obj.sequences = sequences;
            obj.cfg = cfg;
            
            % SVM_L1_StationaryTransit
            obj.classifier_tree.NodeClassifier.Initialize(sequences, cfg);
            
            % SVM_L2_StaticMoving            
            obj.classifier_tree.FirstChild.NodeClassifier.Initialize(sequences, cfg);
            
            % SVM_L3_SittingStanding
            obj.classifier_tree.FirstChild.SecondChild.NodeClassifier.Initialize(sequences, cfg);
            
            % SVM_L2_BoxOpen            
            obj.classifier_tree.SecondChild.NodeClassifier.Initialize(sequences, cfg);
            
            % SVM_L3_DrivingPassenger            
            obj.classifier_tree.SecondChild.FirstChild.NodeClassifier.Initialize(sequences, cfg);
            
            % SVM_L3_WalkingWheels
            obj.classifier_tree.SecondChild.SecondChild.NodeClassifier.Initialize(sequences, cfg);

        end
        
        function StripSeqData(obj)
            obj.sequences = {};

            obj.classifier_tree.NodeClassifier.StripSeqData();            
            obj.classifier_tree.FirstChild.NodeClassifier.StripSeqData();
            obj.classifier_tree.FirstChild.SecondChild.NodeClassifier.StripSeqData();
            obj.classifier_tree.SecondChild.NodeClassifier.StripSeqData();
            obj.classifier_tree.SecondChild.FirstChild.NodeClassifier.StripSeqData();
            obj.classifier_tree.SecondChild.SecondChild.NodeClassifier.StripSeqData();
        end
        
        function [res_test_accuracy_info, test_ind] = Test(obj)
            obj.test_ind = obj.classifier_tree.NodeClassifier.test_ind;
            obj.test_ind = intersect(obj.test_ind, obj.classifier_tree.FirstChild.NodeClassifier.test_ind);
            obj.test_ind = intersect(obj.test_ind,obj.classifier_tree.FirstChild.SecondChild.NodeClassifier.test_ind);
            obj.test_ind = intersect(obj.test_ind,obj.classifier_tree.SecondChild.NodeClassifier.test_ind);
            obj.test_ind = intersect(obj.test_ind,obj.classifier_tree.SecondChild.FirstChild.NodeClassifier.test_ind);
            obj.test_ind = intersect(obj.test_ind,obj.classifier_tree.SecondChild.SecondChild.NodeClassifier.test_ind);
            test_ind = obj.test_ind;
           
            obj.result_labels_per_seq = {};
            for i=1:numel(test_ind)
                cur_seq = obj.sequences{test_ind(i)};
                obj.result_labels_per_seq{end+1} = cell(numel(cur_seq.Labels),1);
                obj.result_labels_per_seq{end}(:) = {'DontCare'};
            end
            
            obj.test_accuracy_info = AccuracyInfo(numel(obj.classnames));
            obj.test_accuracy_info.SetClassNames(obj.classnames);
            
            fprintf('%s Testing...\n',log_line_prefix);
            
            accumulated_accurcy = BinaryHierarchicalAccuracy();
            
            for i=1:numel(test_ind)               
                cur_seq = obj.sequences{test_ind(i)};
                [~, fname, fname_ext] = fileparts(cur_seq.SequenceName);
                fname = [fname fname_ext];
                %fprintf('%s Testing Tree Classifiers..\n',log_line_prefix);
                rootmask = cellfun('isempty', strfind(cur_seq.Labels,'DontCare'));
                cur_acc = obj.Test_rec(obj.classifier_tree, i, rootmask,0);
                accumulated_accurcy.accumulate(cur_acc);
                fprintf('%s [Test] [%s] Sequence Done: %s.\n',log_line_prefix,fname, cur_acc.GetAccuracyString());
            end

            accumulated_accurcy.confmat = obj.GetConfMat();
            obj.test_accuracy_info = accumulated_accurcy;
            res_test_accuracy_info = obj.test_accuracy_info;
            
            fprintf('%s [Test] Current Iteration Test Accuracy: %s\n',log_line_prefix,accumulated_accurcy.GetAccuracyString());
        end
        
        function confmat = GetConfMat(obj)
            confmat = zeros(numel(obj.classnames));
            
            
            for i=1:numel(obj.test_ind)
                cur_seq = obj.sequences{obj.test_ind(i)};
                valid_label_ind = cellfun('isempty', strfind(cur_seq.Labels,'DontCare'));
                cur_seq_labels = cur_seq.Labels(valid_label_ind);
                valid_res_labels = obj.result_labels_per_seq{i}(valid_label_ind);
                confmat = confmat + confusionmat(cur_seq_labels,valid_res_labels,'ORDER',obj.classnames);
            end
        end
        
       function ind = GetClassIndex(obj,classname)
            ind = 0;
            for i=1:size(obj.classmap,1)
                if (strcmpi(obj.classmap{i,1},classname))
                    ind = i;
                    break;
                end
            end
        end
   
        function RecordLabels(obj, binary_classifier,res_labels,i)
            id = obj.GetClassIndex(binary_classifier.classnames(1));
            if id ~= 0
                obj.result_labels_per_seq{i}(res_labels == -1) = binary_classifier.classnames(1);
            end
            
            id = obj.GetClassIndex(binary_classifier.classnames(2));
            if id ~= 0
                obj.result_labels_per_seq{i}(res_labels == 1) = binary_classifier.classnames(2);
            end

        end
        
        function cur_acc = Test_rec(obj, cur_node, i, mask,depth)
            
            cur_seq = obj.sequences{obj.test_ind(i)};
            cur_acc = BinaryHierarchicalAccuracy();
            
            mask = logical(mask);
            
            res_labels_trimap = zeros(size(mask));
            if(sum(mask) ~= 0)
                res_labels = cur_node.NodeClassifier.TestSequence(cur_seq, mask);
                res_labels_trimap(mask) = res_labels;
                obj.RecordLabels(cur_node.NodeClassifier, res_labels_trimap, i);
            end
            
            ground_truth_trimap = cur_node.NodeClassifier.ConvertLabels(cur_seq);
            
            conf_mat = obj.CompareTrimaps(ground_truth_trimap,res_labels_trimap);
            
            %cur_node.NodeAccuracyInfo.AddExperiment(conf_mat);
            
            cur_acc.AddExperiment(cur_node.NodeClassifier.classnames(1), conf_mat(1,1), sum(conf_mat(1,:),2));
            cur_acc.AddExperiment(cur_node.NodeClassifier.classnames(2), conf_mat(2,2), sum(conf_mat(2,:),2));
            
            [~, fname, fname_ext] = fileparts(cur_seq.SequenceName);
            fname = [fname fname_ext];

            %fprintf('%s %s %s accuracy: %s\n',log_line_prefix,fname,class(cur_node.NodeClassifier),cur_node.NodeAccuracyInfo.GetAccuracyStr());
            
            if ~isempty(cur_node.FirstChild)
                leftmask = zeros(size(mask));
                leftmask(res_labels_trimap==-1)=1;
                h_acc_left = obj.Test_rec(cur_node.FirstChild,i,leftmask,depth+1);
                cur_acc.accumulate(h_acc_left);
            end
            
            if ~isempty(cur_node.SecondChild)
                rightmask = zeros(size(mask));
                rightmask(res_labels_trimap==1)=1;
                h_acc_right = obj.Test_rec(cur_node.SecondChild,i,rightmask,depth+1);
                cur_acc.accumulate(h_acc_right);
            end
            
     
        end
        
        function confmat = CompareTrimaps(obj,ground_truth, result)
           confmat = zeros(2,2);
           confmat(1,1) = sum((ground_truth == -1) .* (result == -1));
           confmat(1,2) = sum(ground_truth == -1) - confmat(1,1);
           
           confmat(2,2) = sum((ground_truth == 1) .* (result == 1));
           confmat(2,1) = sum(ground_truth == 1) - confmat(2,2);
        end
        
        
        function success = Train_with_ind(obj, train_seq_ind)
            % No training here. All classifiers are pre-trained.
            success = 1;
        end        
        
    end
end