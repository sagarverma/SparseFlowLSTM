classdef SVM_L3_SittingStanding < SVMClassifier


    
    methods
        function obj = SVM_L3_SittingStanding()
            obj.classmap = {'Walking',0; ...
                        'Driving',0; ...
                        'Standing',1; ...
                        'Passenger',0;
                        'Wheels',0;
                        'Sitting',-1;
                        'Static',0};
                    
            obj.classnames = {'Sitting','Standing'};
                    
            
        end

        
        function fv = CreateFeatureVectors(obj,data,ind)
            
            wsize = 100;
            
            norm_cumsum_x = zeros(numel(ind),1);
            norm_cumsum_y = zeros(numel(ind),1);
            
            for i=1:numel(ind)
                sframe = max([1, ind(i)-wsize]);
                eframe = min([size(data.LK_X_smoothed,1) ind(i)+wsize]);
                
                cumsum_x = sum(data.LK_X_smoothed(sframe:eframe,:),1);
                cumsum_y = sum(data.LK_Y_smoothed(sframe:eframe,:),1);
                
                norm_cumsum_x(i) = norm(cumsum_x);
                norm_cumsum_y(i) = norm(cumsum_y);
            end
            
            
            
            fv = [data.LK_valid_count_smooth(ind,:), data.Template_response(ind,:), ...
                  data.Clusters_distance(ind,:), ...
                  data.Cluster_top_mean_mag(ind,:), ...
                  data.Cluster_bot_mean_mag(ind,:), ...
                  data.Mean_smooth_magnitude(ind,:), norm_cumsum_x, norm_cumsum_y,...
                  %data.LK_X_smoothed(ind,:),data.LK_X_smoothed(ind,:)];
                   %data.Mean_raw_magnitude(ind,:),...
                  % data.Mean_raw_mag_temporal_stddev(ind,:)];
                   %data.Diff_raw_smooth(ind,:)
                   ];
        end
   
    end
end