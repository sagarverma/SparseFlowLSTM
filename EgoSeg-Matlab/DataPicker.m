classdef DataPicker < handle
   
    properties 
        %MIN_LABELS_PER_CLASS = 15000;
        cfg;
        initialized;
        sequences;
    end
    
    
    
    
    methods
        function obj = DataPicker
            obj.initialized = 0;
        end
        function Initialize(obj,cfg)
            obj.cfg = cfg;
            obj.initialized=1;
        end
    end
    
    methods(Abstract)
        train_ind = PickData(obj,classifier);
    end

    
end