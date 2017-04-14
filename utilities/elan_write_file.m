function elan_write_file(elandoc,fps,output_fname,varargin)
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



%% Helper function
function new_elandoc = elan_update_timeorder_from_tiers(elandoc,fps)
    
    

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