classdef SVM_L2_StaticMoving < SVMClassifier


    
    methods
        function obj = SVM_L2_StaticMoving()
            obj.classmap = {'Walking',0; ...
                        'Driving',0; ...
                        'Standing',1; ...
                        'Passenger',0;
                        'Wheels',0;
                        'Sitting',1;
                        'Static',-1};
                    
            obj.classnames = {'Static','Moving'};
                    

        end

        function fv = CreateFeatureVectors(obj,data,ind)
            fv = [%data.LK_valid_count_smooth(ind,:), data.Template_response(ind,:),...
                  data.Clusters_distance(ind,:), ...
                  data.Mean_smooth_magnitude(ind,:), ...
                  data.Mean_raw_magnitude(ind,:), ...
                  data.Mean_raw_mag_temporal_stddev(ind,:)];
        end
    end
end