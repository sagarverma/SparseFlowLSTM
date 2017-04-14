classdef BinaryHierarchicalAccuracy < handle
    
    properties
        classnames;
        total_samples;
        correct_classification;
        confmat;
    end
    
    methods 
        function obj = BinaryHierarchicalAccuracy()
            obj.classnames = {};
            obj.total_samples = [];
            obj.correct_classification = [];
        end
        
        function ind = AddClass(obj, classname)
            obj.classnames{end+1} = classname;
            obj.total_samples = [obj.total_samples; 0];
            obj.correct_classification = [obj.correct_classification; 0];
            
            ind = numel(obj.classnames);
        end
        
        function AddExperiment(obj, classname, correct_res, total)
            i = obj.getClassIndex(classname);
            if i==0
                i = obj.AddClass(classname);
            end
            
            obj.correct_classification(i) = obj.correct_classification(i) + correct_res;
            obj.total_samples(i) = obj.total_samples(i) + total;
        end
        
        function accstr = GetAccuracyString(obj)
            
            class_acc = obj.correct_classification ./ obj.total_samples;
            mean_acc = mean(class_acc(~isnan(class_acc)));
            
            accstr = sprintf('Mean Accuracy = %.3f over %d samples   [',mean_acc,sum(obj.total_samples));
            
            cnt=0;
            for i=1:numel(class_acc)
                if obj.total_samples(i)==0
                    continue;
                end
                
                cnt=cnt+1;
                if cnt>1
                    accstr = [accstr '    '];
                end
                
                accstr = [accstr sprintf('%.1fK %s@%.3f',double(obj.total_samples(i))/1000,cell2mat(obj.classnames{i}),class_acc(i))];
            end
            accstr = [accstr ']'];
        end
        
        function accumulate(obj, new_acc)
            for i=1:numel(new_acc.classnames)
                
                obj.AddExperiment(new_acc.classnames{i},new_acc.correct_classification(i),new_acc.total_samples(i));
                
            end
            
        end
        
        function ind = getClassIndex(obj,classname)
            ind = 0;
            for i=1:numel(obj.classnames)
                if (strcmpi(obj.classnames{i},classname))
                    ind = i;
                    break;
                end
            end
        end
   
        
        function [class_acc class_counts] = GetClassAccuracy(obj)
            class_counts = obj.total_samples;
            class_acc = obj.correct_classification ./ class_counts;
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
        
    end
end