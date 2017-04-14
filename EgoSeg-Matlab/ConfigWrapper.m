classdef ConfigWrapper < handle
    
    properties
        argsmap;
        
        
        % Put all default values here.
        defaults = {'SVM_MAX_TRAINING_SAMPLES_PER_CLASS',   12500;
                    'PICKER_MIN_LABELS_PER_CLASS', 15000;
                    'SVM_MAX_ITER', 30000;
                    'SVM_KERNEL', 'linear';
                    'SVM_OPT_METHOD', 'SMO';
                    'SVM_AUTO_SCALE', 1;
                    'RANDOM_TRAINING_SET',1;
                    'ID',1;
                    'SVM_ADDITIONAL_OPTS',{};
                    'EXPERIMENT_DATA_ACCURACY_TYPE','avg';
                    'EXPERIMENT_DATA_AUTO_DUMP_PER_ITER',1;
                    };
                
                
    end
    
    methods
        % Argument 'args' should be key-value pairs. Each pair is one row
        % in a 2D cell array.
        function obj = ConfigWrapper(args)

            obj.argsmap = containers.Map();

            for i=1:size(obj.defaults,1)
                obj.argsmap(obj.defaults{i,1}) = obj.defaults{i,2};
            end
        
            if nargin>0
                for i=1:size(args,1)
                    obj.argsmap(args{i,1}) = args{i,2};
                end
            end
            
            if exist('ConfigWrapperIncrementalID.mat','file')
                load('ConfigWrapperIncrementalID.mat','ConfigWrapperIncrementalID');
            else
                ConfigWrapperIncrementalID=0;
            end

            ConfigWrapperIncrementalID = ConfigWrapperIncrementalID + 1;
            
            obj.argsmap('ID') = ConfigWrapperIncrementalID;
            obj.argsmap('HOSTNAME') = getComputerName();
            
            save('ConfigWrapperIncrementalID.mat','ConfigWrapperIncrementalID');

        end

        
        function val = get(obj,arg)
            if ~obj.argsmap.isKey(arg)
                error('ConfigWrapper doesn''t have a key named ''%s''.',arg);
            end
            
            val = obj.argsmap(arg);
        end
        
        
        function carray = ToKeyValCellArray(obj)
            k = obj.argsmap.keys;
            
            carray = cell(numel(k),2);
            for i=1:numel(k)
                carray{i,1} = k{i};
                carray{i,2} = obj.Cell2StrRecursive(obj.argsmap(k{i}));
            end
            
        end
    end
        
    methods (Access = private)
        function s = Cell2StrRecursive(obj,c)
            if  isnumeric(c)
                s = mat2str(c); 
                return
            elseif ischar(c)
                s = c;
                return;
            end
            
            if ~iscell(c)
                error('RecCell2Str expecting c to be a cell array here.');
            end
            
            s = '{';
            for i=1:numel(c)
                if i>1
                    s = sprintf('%s,',s);
                end
                
                s = sprintf('%s%s',s,obj.Cell2StrRecursive(c{i}));
            end
            
            s = sprintf('%s}',s);
        end

    end
      
    
end