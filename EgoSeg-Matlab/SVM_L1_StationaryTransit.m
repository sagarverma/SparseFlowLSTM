classdef SVM_L1_StationaryTransit < SVMClassifier


    
    methods
        function obj = SVM_L1_StationaryTransit()
            obj.classmap = {'Walking',1; ...
                        'Driving',1; ...
                        'Standing',-1; ...
                        'Passenger',1;
                        'Wheels',1;
                        'Sitting',-1;
                        'Static',-1};
                    
            obj.classnames = {'Stationary','Transit'};
                    
        end
        
        
        function fv = CreateFeatureVectors(obj,data,ind)
            fv = [data.LK_valid_count_smooth(ind,:), data.Template_response(ind,:), data.Clusters_distance(ind,:),...
                  data.Mean_smooth_magnitude(ind,:)];
        end
    end
end