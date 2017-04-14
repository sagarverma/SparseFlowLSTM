classdef DataRepository < handle
   
    
    properties(Constant)
        
    end
    
    
    properties
        sequences;
        csv_suffix;
    end
    
    
    methods
        
        function obj = DataRepository(csv_suffix)
            obj.sequences = {};
            %obj.LK_CONFIG_NAME = '_config-10x5-nooverlap';
            obj.csv_suffix = csv_suffix;
        end
        
        
        function seqdata = GetSequenceData(obj, seq_name)
            seqdata = [];
            for i=1:numel(obj.sequences)
                [~, seqname_a] = fileparts(seq_name);
                [~, seqname_b] = fileparts(obj.sequences{i}.SequenceName);
                
                if strcmp(seqname_a,seqname_b)
                    seqdata = obj.sequences{i};
                    break;
                end
            end
            
%             if isempty(seqdata)
%                 error('%s Cannot find sequence "%s" in datarep!',log_line_prefix,seq_name);
%             end
        end

        function AddSequenceData(obj, seq_data)
            cnt = numel(obj.sequences);
            obj.sequences{cnt+1} = seq_data;
        end

        function AddSequences(obj,seq_list)
            seq_fnames = Util.ExpandFileList(seq_list);
            
            for i=1:numel(seq_fnames)
                fprintf('%s Processing video %s...',log_line_prefix,seq_fnames{i});
                try 
                    cur_vid = Util.LoadVidDataFromMat(seq_fnames{i},obj.csv_suffix,'returnonly');
                    
                    if (isempty(cur_vid.SequenceData.Train_mask))
                        cur_vid.SequenceData.Train_mask = zeros(size(cur_vid.SequenceData.Labels));
                    end
                    
                    obj.AddSequenceData(cur_vid.SequenceData);
                catch err
                    fprintf('\n%s Error loading "%s". Details: %s. Skipping.',log_line_prefix,seq_fnames{i},err.message);
                end
                fprintf('Done.\n');
            end
        end

        
        function [labels_map] = GetUniqueLabels(obj)
             % Collect unique labels
            uniq_labels = {};
            for i=1:numel(obj.sequences)
                uniq_labels = unique(cat(1,uniq_labels,unique(obj.sequences{i}.Labels)));
                fprintf('%s Processing labels from video %s...\n',log_line_prefix,obj.sequences{i}.SequenceName);
            end
            
            labels_map = containers.Map();
            j=1;
            for i=1:numel(uniq_labels)
                if (strcmp(uniq_labels{i},'DontCare')==1)
                    labels_map(uniq_labels{i}) = 0;
                else
                    labels_map(uniq_labels{i}) = j;
                    j = j+1;
                end 
            end
        end
        
        function ExportSequencesDataMultipleFiles(obj,output_prefix,remove_dontcare_data)
            
            labels_map = obj.GetUniqueLabels();
            
            
            for i=1:numel(obj.sequences)
                fprintf('%s Processing video %s...\n',log_line_prefix,obj.sequences{i}.SequenceName);
                
                [features, labels] = obj.sequences{i}.ConcatFeaturesData(labels_map);
                
                if (remove_dontcare_data==1)
                    valid_data = (labels~=0);
                    
                    features = features(valid_data,:);
                    labels = labels(valid_data,:);
                end
                
                
                [d seq_name e] = fileparts(obj.sequences{i}.SequenceName);
                
                save([output_prefix seq_name] ,'features','labels','labels_map','-v7.3');
            end
            
        end
        
        
        function ExportSequencesDataSingleFile(obj,outputname,remove_dontcare_data)
            
            labels_map = obj.GetUniqueLabels();
            
            all_features = [];
            all_labels = [];
            
            for i=1:numel(obj.sequences)
                fprintf('%s Processing video %s...\n',log_line_prefix,obj.sequences{i}.SequenceName);
                
                [features, labels] = obj.sequences{i}.ConcatFeaturesData(labels_map);
                
                if (remove_dontcare_data==1)
                    valid_data = (labels~=0);
                    
                    features = features(valid_data,:);
                    labels = labels(valid_data,:);
                end
                
                all_features = [all_features ; features];
                all_labels = [all_labels ; labels];
                    
            end
            
            % Rename before save.
            features = all_features;
            labels = all_labels;
            
            save(outputname ,'features','labels','labels_map','-v7.3');
        end
        

    end
    
    
    
end