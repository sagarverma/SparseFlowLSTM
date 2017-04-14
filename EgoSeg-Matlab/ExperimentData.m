classdef ExperimentData < handle
    properties

        sequence_names;
        experiment_type;
        experiment_cfg;
        experiment_timestamp_str;
        classifiers;
        
    end
    
    
    methods
        function obj = ExperimentData(seq,exp_type,exp_cfg)
            
            for i=1:numel(seq)
                obj.sequence_names{i} = seq{i}.SequenceName;
            end
            
            obj.experiment_type = exp_type;
            obj.experiment_cfg = exp_cfg;
            obj.experiment_timestamp_str = datestr(now,'mmddTHHMMSS');
            obj.classifiers={};
            
        end
        
        function AddExperiment(obj,classifier)
            classifier.StripSeqData();
            obj.classifiers{end+1} = classifier;
        end
        
        
        function best_ind = GetBestClassifierIndByAccuracy(obj)
            best_acc = -inf;
            best_ind = -1;
            for i=1:numel(obj.classifiers)                
                cur_classifier_acc = obj.GetClassifierAccuracy(i);
                if (cur_classifier_acc > best_acc)
                    best_ind=i;
                    best_acc = cur_classifier_acc;
                end
            end
        end
        
        function [cur_classifier_acc acc_type] = GetClassifierAccuracy(obj, i)
            try
                acc_type=obj.experiment_cfg.get('EXPERIMENT_DATA_ACCURACY_TYPE');
            catch
                acc_type='avg';
            end

            switch (acc_type)
                case 'min'
                    cur_classifier_acc = obj.classifiers{i}.test_accuracy_info.GetMinClassAccuracy();
                case 'avg'
                    cur_classifier_acc = obj.classifiers{i}.test_accuracy_info.GetAccuracy();
                case 'weighted'
                    cur_classifier_acc = obj.classifiers{i}.test_accuracy_info.GetWeightedAccuracy();
                otherwise 
                    error('Unknown accuracy type.');
            end                
        end
        
        function [best_classifier, best_weight_classifier] = PrintBestClassifiersByAccuracy(obj)
            
            best_ind = obj.GetBestClassifierIndByAccuracy();
            %best_classifier = obj.classifiers{best_ind};
            fprintf('%s Best Classifier By Accuracy: %.2f%%\n',log_line_prefix,obj.GetClassifierAccuracy(best_ind)*100);
            
        end
        
        
        function experiment_fname = Save(obj,varargin)
                
                best_classifier_ind = obj.GetBestClassifierIndByAccuracy();
                [best_acc acc_type]= obj.GetClassifierAccuracy(best_classifier_ind);
                
                
                switch numel(varargin)
                    case 0
                        experiment_fname = sprintf('exp_result_%s_ID%d_%s_acc-%s-%d_%s.mat',obj.experiment_cfg.get('HOSTNAME'),obj.experiment_cfg.get('ID'),obj.experiment_type,...
                                                                        acc_type,floor(best_acc*100),...
                                                                        obj.experiment_timestamp_str);
                    case 1
                        experiment_fname = varargin{1};
                    otherwise
                        error('Invalid number of arguments. Expecting either 0 or 1 args.');
                end
           
                experiment_data = obj;
                save(experiment_fname,'experiment_data');
                
                fprintf('%s Experiment saved to %s.\n',log_line_prefix,experiment_fname);
        end
        
    end
    
    methods(Static)
        function experiment_data = Load(experiment_fname,datarep)
            
            [~, ~, ext] = fileparts(experiment_fname);
            if strcmp(ext,'.mat')==0
                experiment_fname = [experiment_fname '.mat'];
            end 
            
            experiment_data=[];
            load(experiment_fname,'experiment_data');
            
            if ~exist('datarep','var')
                return;
            end
            
            new_rep = DataRepository();
            for i=1:numel(experiment_data.sequence_names)
                seq = datarep.GetSequenceData(experiment_data.sequence_names{i});
                
                if ~isempty(seq)
                    new_rep.AddSequenceData(seq);
                else
                    new_rep.AddSequences({experiment_data.sequence_names{i}});
                end
            end
            
            for i=1:numel(experiment_data.classifiers)
                experiment_data.classifiers{i}.Initialize(new_rep.sequences,experiment_data.experiment_cfg);
            end
            
        end
    end
    
end