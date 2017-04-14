function elandata = elan_load_file(filename,sequence_fps,numframes,tier_name,mapping,varargin)
% READ_ELAN_FILE
%
% Reads an annotation tier from a given .EAF file. Meta-data of the
% corresponding video file (FPS, number of frames) must be provided.
%
% filename - full path to .eaf file to read.
% sequence_fps - the FPS of the corresponding video file.
% numframes - number of frames in the corresponding video file.
% tier_name - name of the tier in the .eaf file that contains the labels to be read.
% mapping - Use this to renmae the labels in the .eaf file. Variable mapping is a 2xN cell array, where N is the number of labels. The first
% 			row should contain the original labels and the second the new labels. The
% 			values in the first row must be unique.

    if numel(mapping)>0
        labelmap = containers.Map(mapping(1,:),mapping(2,:));
    end
    
    unique_list_only = 0;
    if (numel(varargin)>1)
        switch varargin{2}
            case 'uniquelistonly'
                unique_list_only = 1;
            otherwise 
                error('Unknown option "%s".',varargin{2});
        end
    end

    X = xml_read(filename);
    
    start_frame=1;
    end_frame=numframes;
    
    time_units = X.HEADER.ATTRIBUTE.TIME_UNITS;
    if ~strcmpi(time_units,'milliseconds')
        error('Expecting time units to be "milliseconds"');
    end

    elandata.orig_time_units = 'milliseconds';
    
    
    
    time_order_hashmap = containers.Map();
    
    for i=1:numel(X.TIME_ORDER.TIME_SLOT)
            cur_child = X.TIME_ORDER.TIME_SLOT(i);
            ts_id = cur_child.ATTRIBUTE.TIME_SLOT_ID;
            ts_value = cur_child.ATTRIBUTE.TIME_VALUE;
            frame_num = round(ts_value/(1000/sequence_fps)+1);
            time_order_hashmap(ts_id) = frame_num;
    end
    
    unique_labels = containers.Map();
    unique_labels('DontCare') = 1;
    unique_labels_count = 1;
    
    if ~unique_list_only
        labels = repmat({'DontCare'},[(end_frame-start_frame+1) 1]);
        labels_idx = ones(end_frame-start_frame+1,1);
    else
        labels = {};
    end
    

    
    % Process all tiers. Process the requested tier  along the way as well.
    tier_idx = 0;
    for t=1:numel(X.TIER)
            
            tier_ann = X.TIER(t).ANNOTATION;
            
            % Process the tier and its annotations.
            for i=1:numel(tier_ann)
                    
                    ts1 = tier_ann(i).ALIGNABLE_ANNOTATION.ATTRIBUTE.TIME_SLOT_REF1;
                    ts2 = tier_ann(i).ALIGNABLE_ANNOTATION.ATTRIBUTE.TIME_SLOT_REF2;
                    sframe = time_order_hashmap(ts1);
                    eframe = time_order_hashmap(ts2);

                    % Add frame numbers to xml-tree.
                    tier_ann(i).ALIGNABLE_ANNOTATION.ATTRIBUTE.START_FRAME = sframe;
                    tier_ann(i).ALIGNABLE_ANNOTATION.ATTRIBUTE.END_FRAME = eframe;
                    
                    % If this is the selected tier, save its labels.
                    if strcmpi(X.TIER(t).ATTRIBUTE.TIER_ID,tier_name)
                           tier_idx = i;
                
            	
                            label = strtrim(tier_ann(i).ALIGNABLE_ANNOTATION.ANNOTATION_VALUE);

                             if numel(mapping)>0
                                 if labelmap.isKey(label)
                                    label = labelmap(label);
                                 else
                                    label = 'DontCare';
                                 end
                                 
                             end

                            if ~unique_labels.isKey(label)
                                unique_labels_count = unique_labels_count + 1;
                                unique_labels(label) = unique_labels_count;
                            end


                            % Assign the labels.
                            if ~unique_list_only
                                for j=sframe:eframe
                                    labels{j} = label;
                                    labels_idx(j) = unique_labels(label);
                                end
                            end
                    end

             end
            X.TIER(t).ANNOTATION = tier_ann;
          
    end
    
    if tier_idx == 0
        warning('Could not find tier "%s".',tier_name);
    end
        
    elandata.elan_doc = X;
    elandata.labels = labels;
    elandata.labels_idx = labels_idx;
    elandata.unique_labels = unique_labels;
end
