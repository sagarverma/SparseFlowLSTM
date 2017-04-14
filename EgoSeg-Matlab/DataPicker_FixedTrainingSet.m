classdef DataPicker_FixedTrainingSet < DataPicker
    
   properties
       
   end
   
   methods
       function obj = DataPicker_FixedTrainingSet(sequences)
            obj.sequences = sequences;
       end
       
       
        
        function [train_ind ] = PickData(obj,classifier)

            train_ind = [];
            
            for i=1:size(classifier.classmap,1)
                if classifier.classmap{i,2} == 0
                    continue;
                end
                
                cur_class_count = 0;
                for j=1:numel(train_ind)
                    cur_vid_data = obj.sequences{train_ind(j)};
                    curclass_ind = find(not(cellfun('isempty', strfind(cur_vid_data.Labels,classifier.classmap{i,1}))));
                    
                    curclass_mask = cur_vid_data.Train_mask(curclass_ind);
                    curclass_ind(curclass_mask==0) = [];
                    
                    if ~isempty(curclass_ind)
                        cur_class_count = cur_class_count + numel(curclass_ind);
                        
                        if cur_class_count > obj.cfg.get('MIN_LABELS_PER_CLASS')
                            break;
                        end
                            
                    end
                end
                
                failed_list = [];
                while cur_class_count < obj.cfg.get('MIN_LABELS_PER_CLASS')
                    not_train_yet = setdiff(1:numel(obj.sequences),train_ind);
                    
                    if numel(failed_list) == numel(not_train_yet)
                        fpritnf('%s Class %s - cant find enough train data!\n',log_line_prefix,classifier.classmap{i,1});
                        break;
                    end
                    
                    not_train_yet = setdiff(not_train_yet,failed_list);
                    
                    choosen_seq_ind = not_train_yet(randi(numel(not_train_yet),1,1));
                    
                    cur_vid_data = obj.sequences{choosen_seq_ind};
                    curclass_ind = find(not(cellfun('isempty', strfind(cur_vid_data.Labels,classifier.classmap{i,1}))));
                    
                    curclass_mask = cur_vid_data.Train_mask(curclass_ind);
                    curclass_ind(curclass_mask==0) = [];
                    
                    if ~isempty(curclass_ind)
                        cur_class_count = cur_class_count + numel(curclass_ind);
                        train_ind = [train_ind; choosen_seq_ind];
                    else
                        failed_list = [failed_list; choosen_seq_ind];
                    end
                    
                    
                end
                
                
                
            end
            
        end
            
        

        
       
   end
    
    
end