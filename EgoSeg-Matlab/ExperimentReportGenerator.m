classdef ExperimentReportGenerator < handle

    
    properties
       
        exp_file_list;
        exp_id;
        exp_hostname;
    end
    
    methods
        
        function obj = ExperimentReportGenerator(exp_id,exp_hostname,dir_prefix)
        
            if nargin<=1
                exp_hostname = '';
            end
            
            if nargin<=2
                dir_prefix = '.';
            end
            
            if numel(exp_hostname)>0
                exp_hostname = [exp_hostname '_'];
            end
            
            obj.exp_file_list = Util.ExpandFileList(sprintf('%s/exp_result_%sID%d*.mat',dir_prefix,exp_hostname,exp_id));
            obj.exp_id = exp_id;
            obj.exp_hostname = exp_hostname;
            
        end
        
        
        function GenerateReport(obj)
            
            output_fname = sprintf('exp_report_ID%d',obj.exp_id);
            
            acc_table = {'Classifier','Accuracy','Accuracy 1st Class','Accuracy 2nd Class','Num Samples 1st Class','Num Samples 2nd Class'};
            
            cnt = 2;
            
            % Columns: 'Classifier','Accuracy','Accuracy 1st Class','Accuracy 2nd Class','Num Samples 1st Class','Num Samples 2nd Class'
            for i=1:numel(obj.exp_file_list)
                
                ED = ExperimentData.Load(obj.exp_file_list{i});
                
                best_classifier = ED.classifiers{ED.GetBestClassifierIndByAccuracy()};

                [class_acc, class_counts] = best_classifier.test_accuracy_info.GetClassAccuracy();
                
                acc_table{cnt,1} = sprintf('%s vs. %s',best_classifier.classnames{1},best_classifier.classnames{2});
                acc_table{cnt,2} = sprintf('%d%%',uint32(round(best_classifier.test_accuracy_info.GetAccuracy() * 100)));
                acc_table{cnt,3} = sprintf('%d%%',uint32(round(class_acc(1)*100)));
                acc_table{cnt,4} = sprintf('%d%%',uint32(round(class_acc(2)*100)));
                acc_table{cnt,5} = sprintf('%dK',uint32(class_counts(1)/1000));
                acc_table{cnt,6} = sprintf('%dK',uint32(class_counts(2)/1000));
                
                
                clear ED;
                
                cnt = cnt + 1;
            end
            
            cnt=cnt+2;
            
            
            output_fname = sprintf('exp_report_ID%d',obj.exp_id);
            
            latextable(acc_table,'name',[output_fname '.tex'],'append',0,'tablename',sprintf('Experiment ID%d: Per-Classifier Accuracy',obj.exp_id));
            
            
            for i=1:numel(obj.exp_file_list)
                ED = ExperimentData.Load(obj.exp_file_list{i});
                
                best_classifier = ED.classifiers{ED.GetBestClassifierIndByAccuracy()};
                confmat = best_classifier.test_accuracy_info.confmat;
                
                [class_acc, class_counts] = best_classifier.test_accuracy_info.GetClassAccuracy();
                
                conftab = {'','Prediction','';
                           'Ground Truth',best_classifier.classnames{1},best_classifier.classnames{2}} ;
                conftab{3,1} = best_classifier.classnames{1};
                conftab{4,1} = best_classifier.classnames{2};
                
                conftab{3,2} = sprintf('%d%% (%d)',uint32(100*(confmat(1,1)/sum(confmat(1,:),2))),confmat(1,1));
                conftab{3,3} = sprintf('%d%% (%d)',uint32(100*(confmat(1,2)/sum(confmat(1,:),2))),confmat(1,2));
                conftab{4,2} = sprintf('%d%% (%d)',uint32(100*(confmat(2,1)/sum(confmat(2,:),2))),confmat(2,1));
                conftab{4,3} = sprintf('%d%% (%d)',uint32(100*(confmat(2,2)/sum(confmat(2,:),2))),confmat(2,2)); 
                
                acc_table(cnt:cnt+3,1:3) = conftab;
                cnt = cnt + 6;
                
                tabname = sprintf('Experiment ID%d: Confusion Matrix %s vs. %s',obj.exp_id,best_classifier.classnames{1},best_classifier.classnames{2});
                latextable(conftab,'name',[output_fname '.tex'],'append',1,'tablename',tabname,'Vline',[1],'Hline',[2]);
            end
            
            
            xlswrite(output_fname,acc_table);
            
            
        end
            
            
        
    end
    
    
    
end
