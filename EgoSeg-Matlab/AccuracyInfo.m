classdef AccuracyInfo < handle
    
    properties
        confmat;
        classnames;
    end
    
    methods
        function obj = AccuracyInfo(num_classes)
            obj.confmat = zeros(num_classes,num_classes);
            for i=1:num_classes
                obj.classnames{i} = i;
            end
        end
        
        function AddExperiment(obj,cur_exp_confmat)
            obj.confmat = obj.confmat + cur_exp_confmat;
        end
        
        function [class_acc class_counts] = GetClassAccuracy(obj)
            class_counts = sum(obj.confmat,2);
            class_acc = diag(obj.confmat) ./ class_counts;
            
        end
        
        function accuracy = GetAccuracy(obj)
            class_acc = obj.GetClassAccuracy();
            class_acc(isinf(class_acc))=[];
            class_acc(isnan(class_acc))=[];
            accuracy = mean(class_acc);
        end

        function waccuracy = GetWeightedAccuracy(obj)
            [class_acc class_counts] = obj.GetClassAccuracy();
            class_acc(class_counts==0)=0;
            
            waccuracy = (class_acc .* class_counts) / sum(class_counts);
        end

        function accuracy = GetMinClassAccuracy(obj)
            class_acc = obj.GetClassAccuracy();
            class_acc(isinf(class_acc))=[];
            class_acc(isnan(class_acc))=[];
            accuracy = min(class_acc);
        end
        
        function SetClassNames(obj,cnames)
            if numel(cnames)~=numel(obj.classnames)
                error('Wrong number of classes in arg cnames.');
            end
            obj.classnames = cnames;
        end
        
        function accstr = GetAccuracyStr(obj)
            [class_acc class_counts] = obj.GetClassAccuracy();
            
            accstr = sprintf('Mean Accuracy = %.3f over %d samples   [',obj.GetAccuracy(),sum(class_counts));
            
            
            for i=1:numel(class_acc)
                if i>1
                    accstr = [accstr '    '];
                end
                
                accstr = [accstr sprintf('%.1fK %s@%.3f',double(class_counts(i))/1000,obj.classnames{i},class_acc(i))];
            end
            accstr = [accstr ']'];
        end
    end
    
    
end