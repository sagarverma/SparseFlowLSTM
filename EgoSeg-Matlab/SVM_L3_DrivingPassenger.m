classdef SVM_L3_DrivingPassenger < SVMClassifier

    methods
        function obj = SVM_L3_DrivingPassenger()
            obj.classmap = {'Walking',0; ...
                        'Driving',-1; ...
                        'Standing',0; ...
                        'Passenger',1; ...
                        'Wheels',0; ...
                        'Sitting',0; ...
                        'Static',0};
                    
            obj.classnames = {'Driving','Passenger'};
        end
        
        
        
         function ring_template_response = FindTemplateResponse_SingleFOE(obj, data, frameMX, frameMY,  mag_mask, ring_mask)
            
            cx=double(5.5);
            cy=double(2.5);

            meshx = data.meshx_orig-cx;
            meshy = data.meshy_orig-cy;
            template_magnitude = sqrt(meshx.^2+meshy.^2);

            % Normalize template to unit vectors.
            meshx = meshx ./ template_magnitude;
            meshy = meshy ./ template_magnitude;

            % Project the motion of the current frame (represented by the
            % approx slopes of the displacement curves) on the template and get
            % the response.
            resp_mat = meshx .* frameMX + meshy .* frameMY;

            
            ang_mask = resp_mat<cos(SequenceData.max_deviation_angle);
            resp_mat(mag_mask) = 0;
            resp_mat(ang_mask) = 0;
            resp_mat(~ring_mask) = 0;

            ring_template_response = sum(resp_mat(:)~=0);
         end
        
        function fv = CreateFeatureVectors(obj,data,ind)


%             local_inner_ring_sum = zeros(numel(ind),1);
%             local_outer_ring_sum = zeros(numel(ind),1);
%             %local_sym_test = zeros(numel(ind),1);
%              
%             inner_mask = zeros(data.num_y_cells,data.num_x_cells);
%             xmargin=2;
%             ymargin=1;
%             inner_mask((1+ymargin):(data.num_y_cells-ymargin),(1+xmargin):(data.num_x_cells-xmargin)) = 1;
%             outer_mask= 1 - inner_mask;
%             
%             for i=1:numel(ind)
% 
%                 frameMX = reshape(data.LK_X_smoothed(ind(i),:),data.num_x_cells,data.num_y_cells)';
%                 frameMY = reshape(data.LK_Y_smoothed(ind(i),:),data.num_x_cells,data.num_y_cells)';
%         
%                 %local_sym_test(i) = abs(sum(frameMX(:))) + abs(sum(frameMY(:)));
%                 
%                 frame_magnitude = sqrt(frameMX.^2 + frameMY.^2);
%                 
%                 mag_mask = frame_magnitude < SequenceData.min_motion_magnitude;
%                 
%                 frameMX = frameMX ./ frame_magnitude;
%                 frameMY = frameMY ./ frame_magnitude;
%                 
%                 local_inner_ring_sum(i) = obj.FindTemplateResponse_SingleFOE(data, frameMX, frameMY,  mag_mask, inner_mask);
%                 local_outer_ring_sum(i) = obj.FindTemplateResponse_SingleFOE(data, frameMX, frameMY,  mag_mask, outer_mask);
%                 
%             end
                
            fv = [data.LK_valid_count_smooth(ind,:), data.Template_response(ind,:), data.Clusters_distance(ind,:),...
                  data.Mean_smooth_magnitude(ind,:)];
        end
    end
end