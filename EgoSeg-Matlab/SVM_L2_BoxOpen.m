classdef SVM_L2_BoxOpen < SVMClassifier


    
    methods
        function obj = SVM_L2_BoxOpen()
            obj.classmap = {'Walking',1; ...
                        'Driving',-1; ...
                        'Standing',0; ...
                        'Passenger',-1;
                        'Wheels',1;
                        'Sitting',0;
                        'Static',0};
                    
            obj.classnames = {'Box','Open'};
                    

        end

        function fv = CreateFeatureVectors(obj,data,ind)
            fv = [data.LK_valid_count_smooth(ind,:), data.Template_response(ind,:), data.Clusters_distance(ind,:),...
                  data.Mean_smooth_magnitude(ind,:)];
        end
    end
end