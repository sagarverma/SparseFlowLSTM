classdef SequenceData < handle
    
    properties (Constant)
        foe_margin = 0.25;
        num_x_cells = 10;
        num_y_cells = 5;
        min_motion_magnitude = 0.002;
        max_deviation_angle = 1.5708;
        lk_valid_count_smooth_kernel_size = 200;
        lk_smooth_kernel_size = 1000;
        cluster_size_percent = 0.06;
    end
    
    properties
        LK_X_raw;
        LK_Y_raw;
        LK_X_smoothed;
        LK_Y_smoothed;
        LK_valid_count;
        LK_valid_count_smooth;
        Template_response;
        Clusters_distance;
        Cluster_top_mean_mag;
        Cluster_bot_mean_mag;
        Diff_raw_smooth;
        Mean_smooth_magnitude;
        Mean_raw_magnitude;
        Mean_raw_mag_temporal_stddev;
        FOE_x;
        FOE_y;
        FOE_center_dist;
        Labels;
        meshy_orig;
        meshx_orig;
        Train_mask;
        SequenceName;
        FPS;
    end
    
    
    methods
        function obj = SequenceData(rawdata,seqname)
            obj.LK_X_raw = [];
            obj.LK_Y_raw = [];
            obj.LK_X_smoothed = [];
            obj.LK_Y_smoothed = [];
            obj.LK_valid_count = [];
            obj.LK_valid_count_smooth = [];
            obj.Labels = {};
            obj.Train_mask = [];
            obj.Template_response = [];
            obj.Clusters_distance = [];
            obj.Diff_raw_smooth = [];
            obj.FOE_x = [];
            obj.FOE_y = [];
            obj.Cluster_top_mean_mag = [];
            obj.Cluster_bot_mean_mag = [];
            obj.Mean_smooth_magnitude = [];
            obj.Mean_raw_magnitude = [];
            obj.Mean_raw_mag_temporal_stddev = [];
           
            [obj.meshx_orig, obj.meshy_orig] = meshgrid(1:obj.num_x_cells,1:obj.num_y_cells);
            obj.SequenceName = seqname;
            
            
            
            obj.Labels = cat(1,obj.Labels,rawdata.ground_truth_data.labels{1:rawdata.num_frames});
            obj.FPS = rawdata.fps;
            
            
            obj.Train_mask = zeros(rawdata.num_frames,1);
            if (isfield(rawdata,'train_mask'))
                trainmask_ind = find(not(cellfun('isempty', strfind(rawdata.train_mask.labels,'Train'))));
                trainmask_ind = trainmask_ind(trainmask_ind<=rawdata.num_frames);
                obj.Train_mask(trainmask_ind) = 1;
            end
            
            obj.CalculateFeatures(rawdata,1:rawdata.num_frames);
        end
        
        
                
        
        
         function template_response_current_foe = FindTemplateResponse_SingleFOE(obj, frameMX, frameMY, foe_x, foe_y, mag_mask)
            
            cx=double(foe_x+0.5);
            cy=double(foe_y+0.5);

            meshx = obj.meshx_orig-cx;
            meshy = obj.meshy_orig-cy;
            template_magnitude = sqrt(meshx.^2+meshy.^2);

            % Normalize template to unit vectors.
            meshx = meshx ./ template_magnitude;
            meshy = meshy ./ template_magnitude;

            % Project the motion of the current frame (represented by the
            % approx slopes of the displacement curves) on the template and get
            % the response.
            resp_mat = meshx .* frameMX + meshy .* frameMY;

            ang_mask = resp_mat<cos(obj.max_deviation_angle);
            resp_mat(mag_mask) = 0;
            resp_mat(ang_mask) = 0;

            template_response_current_foe = sum(resp_mat(:)~=0);
        end
            
        function CalculateFeatures(obj,data,ind)
            
            
            Hsmooth = fspecial('average',[obj.lk_valid_count_smooth_kernel_size,1]);
            local_LK_valid_count = sum(data.LK_valid)';
            local_smooth_valid_block_count = imfilter(local_LK_valid_count,Hsmooth,'same','replicate');
            
            % Valid LK count, and smoothed valid LK count.
            obj.LK_valid_count = [obj.LK_valid_count ;local_LK_valid_count(ind)];
            obj.LK_valid_count_smooth = [obj.LK_valid_count_smooth ;local_smooth_valid_block_count(ind)];
            
            local_mean_raw_magnitude = mean(sqrt(data.LK_X'.^2  + data.LK_Y'.^2),2);
            obj.Mean_raw_magnitude = [obj.Mean_raw_magnitude; local_mean_raw_magnitude];
            
            obj.LK_X_raw = [obj.LK_X_raw; data.LK_X'];
            obj.LK_Y_raw = [obj.LK_Y_raw; data.LK_Y'];
            
            Hsmooth = fspecial('average',[obj.lk_smooth_kernel_size,1]);
            local_LK_X_smoothed = imfilter(data.LK_X',Hsmooth,'same','replicate');
            local_LK_Y_smoothed = imfilter(data.LK_Y',Hsmooth,'same','replicate');

            obj.LK_X_smoothed = [obj.LK_X_smoothed; local_LK_X_smoothed(ind,:)];
            obj.LK_Y_smoothed = [obj.LK_Y_smoothed; local_LK_Y_smoothed(ind,:)];
            
            local_diff_raw_smooth = sqrt(sum([data.LK_X'-local_LK_X_smoothed(ind,:), data.LK_Y'-local_LK_Y_smoothed(ind,:)].^2,2));
            
            obj.Diff_raw_smooth = [obj.Diff_raw_smooth; local_diff_raw_smooth];
            
            xmargin=uint32(obj.foe_margin*obj.num_x_cells);
            ymargin=uint32(obj.foe_margin*obj.num_y_cells);

            local_template_response = zeros(size(local_LK_X_smoothed,1),1);
            local_clusters_distance = zeros(size(local_LK_X_smoothed,1),1);
            local_foe_x = zeros(size(local_LK_X_smoothed,1),1);
            local_foe_y = zeros(size(local_LK_Y_smoothed,1),1);
            local_foe_dist = zeros(size(local_LK_Y_smoothed,1),1);
            local_cluster_top_mean_mag = zeros(size(local_LK_X_smoothed,1),1);
            local_cluster_bot_mean_mag = zeros(size(local_LK_X_smoothed,1),1);
            local_mean_smooth_magnitude = zeros(size(local_LK_X_smoothed,1),1);
            
            
            max_response_foe_x=obj.num_x_cells/2;
            max_response_foe_y=obj.num_y_cells/2;
            
            
            for i=1:size(local_LK_X_smoothed,1)
                frameMX = reshape(local_LK_X_smoothed(i,:),obj.num_x_cells,obj.num_y_cells)';
                frameMY = reshape(local_LK_Y_smoothed(i,:),obj.num_x_cells,obj.num_y_cells)';
        
                % Normalize frame to unit vectors.
                frame_magnitude = sqrt(frameMX.^2 + frameMY.^2);
                
                local_mean_smooth_magnitude(i) = mean(frame_magnitude(:));
                
                
                sorted_mag = sort(frame_magnitude(:));
        
                cluster_size = ceil(obj.num_x_cells*obj.num_y_cells*obj.cluster_size_percent);

                local_cluster_top_mean_mag(i) = mean(sorted_mag((end-cluster_size+1):end));
                local_cluster_bot_mean_mag(i) = mean(sorted_mag(1:cluster_size));
                local_clusters_distance(i) = local_cluster_top_mean_mag(i) - local_cluster_bot_mean_mag(i);
                
                
                mag_mask = frame_magnitude < obj.min_motion_magnitude;

                frameMX = frameMX ./ frame_magnitude;
                frameMY = frameMY ./ frame_magnitude;
                
                max_response = nan;
                for x=(1+xmargin):(obj.num_x_cells-xmargin)
                    for y=(1+ymargin):(obj.num_y_cells-ymargin)
                        current_foe_resp = obj.FindTemplateResponse_SingleFOE(frameMX, frameMY, x, y, mag_mask);
                        if( current_foe_resp > max_response  || isnan(max_response))
                            max_response = current_foe_resp;
                            max_response_foe_x = x;
                            max_response_foe_y = y;
                        end
                    end
                end
                
                local_template_response(i) = max_response;
                local_foe_x(i) = max_response_foe_x;
                local_foe_y(i) = max_response_foe_y;
                local_foe_dist(i) = norm([double(max_response_foe_x-(obj.num_x_cells/2)); ...
                                       double(max_response_foe_y-(obj.num_y_cells/2))]);
            end
            
            local_mean_raw_mag_temporal_stddev = zeros(size(local_LK_X_smoothed,1),1);
            for i=1:numel(local_mean_raw_mag_temporal_stddev)
                sind = max([1 floor(i-obj.lk_smooth_kernel_size/2)]);
                eind = min([floor(i+obj.lk_smooth_kernel_size/2) numel(local_mean_raw_mag_temporal_stddev)]);
                
                local_mean_raw_mag_temporal_stddev(i) = std(local_mean_raw_magnitude(sind:eind));
            end
            
            obj.Template_response = [obj.Template_response; local_template_response(ind)];
            obj.Clusters_distance = [obj.Clusters_distance ;local_clusters_distance(ind)];
            obj.FOE_x = [obj.FOE_x; local_foe_x];
            obj.FOE_y = [obj.FOE_y; local_foe_y];
            obj.FOE_center_dist = [obj.FOE_center_dist; local_foe_dist];
            obj.Cluster_top_mean_mag = [obj.Cluster_top_mean_mag; local_cluster_top_mean_mag];
            obj.Cluster_bot_mean_mag = [obj.Cluster_bot_mean_mag; local_cluster_bot_mean_mag];
            obj.Mean_smooth_magnitude = [obj.Mean_smooth_magnitude; local_mean_smooth_magnitude];
            obj.Mean_raw_mag_temporal_stddev = [obj.Mean_raw_mag_temporal_stddev; local_mean_raw_mag_temporal_stddev];
        end
        
        
        function [features, labels] = ConcatFeaturesData(obj,label_map)
            
            if isempty(label_map)
                labels = obj.Labels;
            else
                labels = zeros(size(obj.Labels));
                for i=1:size(obj.Labels,1)
                    labels(i) = label_map(obj.Labels{i});
                end
                
            end
            
            % Columns  Data
            % 1-50   : LK_X_raw
            % 51-100 : LK_Y_raw
            % 101-150: LK_X_smoothed 
            % 151-200: LK_Y_smoothed 
            % 201: LK_valid_count 
            % 202: LK_valid_count_smooth
            % 203: Template_response 
            % 204: Clusters_distance 
            % 205: Cluster_top_mean_mag 
            % 206: Cluster_bot_mean_mag 
            % 207: Diff_raw_smooth 
            % 208: Mean_smooth_magnitude 
            % 209: Mean_raw_magnitude 
            % 210: Mean_raw_mag_temporal_stddev
            % 211: FOE_x 
            % 212: FOE_y 
            % 213: FOE_center_dist
            % 214: FPS
            features = [obj.LK_X_raw obj.LK_Y_raw obj.LK_X_smoothed obj.LK_Y_smoothed obj.LK_valid_count obj.LK_valid_count_smooth ...
                        obj.Template_response obj.Clusters_distance obj.Cluster_top_mean_mag obj.Cluster_bot_mean_mag ...
                        obj.Diff_raw_smooth obj.Mean_smooth_magnitude obj.Mean_raw_magnitude obj.Mean_raw_mag_temporal_stddev ...
                        obj.FOE_x obj.FOE_y obj.FOE_center_dist repmat(obj.FPS,size(obj.Labels,1),1)];
        end
        
    end
    
end
    