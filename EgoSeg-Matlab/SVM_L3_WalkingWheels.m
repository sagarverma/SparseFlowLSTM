classdef SVM_L3_WalkingWheels < SVMClassifier


    
    methods
        function obj = SVM_L3_WalkingWheels()
            obj.classmap = {'Walking',-1; ...
                        'Driving',0; ...
                        'Standing',0; ...
                        'Passenger',0;
                        'Wheels',1;
                        'Sitting',0;
                        'Static',0};
                    
            obj.classnames = {'Walking','Wheels'};
                    

        end

        
        function fv = CreateFeatureVectors(obj,data,ind)
            fv = [data.LK_valid_count_smooth(ind,:), data.Template_response(ind,:), data.Clusters_distance(ind,:),...
                  data.Mean_smooth_magnitude(ind,:)];
        end
    end
end