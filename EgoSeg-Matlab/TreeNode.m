classdef TreeNode < handle
    
    properties
        FirstChild;
        SecondChild;
        NodeClassifier;
        %NodeAccuracyInfo;
    end
    
    methods
        function obj = TreeNode(classifier)
            obj.NodeClassifier = classifier;
            obj.FirstChild=[];
            obj.SecondChild=[];
            %obj.NodeAccuracyInfo=AccuracyInfo(numel(classifier.classnames));
            %obj.NodeAccuracyInfo.SetClassNames(classifier.classnames);
        end
        
        
        
    end
end
        