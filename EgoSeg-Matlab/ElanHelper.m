classdef ElanHelper < handle

    methods(Static)
        function elandata = LoadFile(filename,sequence_fps,numframes,tier_name,mapping,varargin)
        % LoadFile
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

    
        function edoc_new = UpdateMediaFile(edoc,new_media_filename)
            % Got new media file name
            edoc.HEADER.MEDIA_DESCRIPTOR.ATTRIBUTE.MEDIA_URL = sprintf('file:///%s',new_media_filename);

            edoc_new = edoc;
        end
        
        function WriteFile(elandoc,fps,output_fname,varargin)
        % ELAN_WRITE_FILE
        %
        % Writes an annotation tier to a given .EAF file. Meta-data of the
        % corresponding video file (FPS) must be provided.
        %
        % elandoc - Elandoc object as returned from elan_load_fille() function.
        % fps - the FPS of the corresponding video file.
        % output_fname - The file name of the new .EAF file.

            elandoc = elan_update_timeorder_from_tiers(elandoc,fps);

            % Remove START_FRAME and END_FRAME attributes from all tiers.
            for t=1:numel(elandoc.TIER)
                    % Process the tier and its annotations.
                    for i=1:numel(elandoc.TIER(t).ANNOTATION)
                            % Add frame numbers to xml-tree.
                            elandoc.TIER(t).ANNOTATION(i).ALIGNABLE_ANNOTATION.ATTRIBUTE=rmfield(elandoc.TIER(t).ANNOTATION(i).ALIGNABLE_ANNOTATION.ATTRIBUTE,'START_FRAME');
                            elandoc.TIER(t).ANNOTATION(i).ALIGNABLE_ANNOTATION.ATTRIBUTE=rmfield(elandoc.TIER(t).ANNOTATION(i).ALIGNABLE_ANNOTATION.ATTRIBUTE,'END_FRAME');
                    end

            end



            Pref.StructItem = false;
            xml_write(output_fname,elandoc,'ANNOTATION_DOCUMENT',Pref);

        end



        %% Helper function used by WriteFile
        function new_elandoc = UpdateTimeorderFromTiers(elandoc,fps)



            unique_ts_ids = containers.Map();

            % Collect all annotated frame ranges.
            for t=1:numel(elandoc.TIER)
                    tier_ann = elandoc.TIER(t).ANNOTATION;
                    % Process the tier and its annotations.
                    for i=1:numel(tier_ann)
                            % Add frame numbers to xml-tree.
                            sframe = tier_ann(i).ALIGNABLE_ANNOTATION.ATTRIBUTE.START_FRAME;
                            eframe = tier_ann(i).ALIGNABLE_ANNOTATION.ATTRIBUTE.END_FRAME;

                            ts1_id = sprintf('ts%d',sframe);
                            ts2_id = sprintf('ts%d',eframe);             

                            unique_ts_ids(num2str(sframe)) = sframe;
                            unique_ts_ids(num2str(eframe)) = eframe;

                            tier_ann(i).ALIGNABLE_ANNOTATION.ATTRIBUTE.TIME_SLOT_REF1 = ts1_id;
                            tier_ann(i).ALIGNABLE_ANNOTATION.ATTRIBUTE.TIME_SLOT_REF2 = ts2_id;

                    end

                    elandoc.TIER(t).ANNOTATION = tier_ann;
            end

            ts_keys = unique_ts_ids.values;
            ts_keys = sort(cell2mat(ts_keys));

            new_TIME_ORDER.TIME_SLOT = repmat(struct(),numel(ts_keys),1);


            for i=1:numel(ts_keys)
                    ts_id = sprintf('ts%d',ts_keys(i));
                    ts_frame_val = max([ts_keys(i)-1 0]);
                    ts_time_val = sprintf('%.0f',(ts_frame_val/fps)*1000);

                    new_TIME_ORDER.TIME_SLOT(i).CONTENT = [];
                    new_TIME_ORDER.TIME_SLOT(i).ATTRIBUTE = struct('TIME_SLOT_ID',ts_id,'TIME_VALUE',ts_time_val);

            end

            new_elandoc = elandoc;

            new_elandoc.TIME_ORDER = new_TIME_ORDER;

        end
        
        function labelmap = InitLabelmapFromElanFile(fname_mask,tier_name)


            if isstr(fname_mask)
                % Convert to cell array.
                temp_fnamemask = fname_mask;
                fname_mask = cell(1,1);
                fname_mask{1} = temp_fnamemask;
            else
                if ~iscell(fname_mask)
                    error('fname_mask variable should be either string with file mask or a cell array of strings with file mask.');
                end
            end


            totalfiles = 0;
            flist=dir('');
            dirprefix_list = {};
            for i=1:numel(fname_mask)
                dirprefix = fileparts(fname_mask{i});
                if numel(dirprefix) > 0
                    dirprefix = [dirprefix '/'];
                end

                templist = dir(fname_mask{i});

                for i=1:numel(templist)
                    if ~templist(i).isdir
                        flist(end+1) = templist(i);
                        dirprefix_list{end+1} = dirprefix;

                        totalfiles = totalfiles+1;
                    end
                end
            end




            fprintf('%sFound %d Elan files.\n',log_line_prefix,numel(flist));
            unique_labels = containers.Map();
            for i=1:numel(flist)

                if ~flist(i).isdir
                    cur_filename = flist(i).name;
                    fullname = sprintf('%s%s',dirprefix_list{i},cur_filename);
                    fprintf('%sProcessing %s..\n',log_line_prefix,cur_filename);

                    elandata = read_elan_file(fullname,0,0,tier_name,[],'uniquelistonly');

                    for i=1:numel(elandata.unique_labels)
                        unique_labels(elandata.unique_labels{i}) = [];
                    end

                end
            end

            labelmap = repmat(unique_labels.keys,2,1);
        end    
    end
end