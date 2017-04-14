classdef FPVUtils < handle
   
    methods(Static)
        
        function traj = LoadVidDataFromMat(fullname,varargin)

            do_assign_in_base=1;
            suffix = '';
            if nargin>1
                suffix = varargin{1};
                if nargin>2
                    if strcmpi('returnonly',varargin{2})
                        do_assign_in_base=0;
                    end
                end

            end


            [filepath filename filext] = fileparts(fullname);
            mat_filename = sprintf('%s/%s%s.mat',filepath,filename,suffix);


            load(mat_filename);

            filename = strrep(filename,'-','_'); % remove invalid chars from var name
            filename = strrep(filename,' ','_'); % remove invalid chars from var name
            filename = strrep(filename,'[','_'); % remove invalid chars from var name
            filename = strrep(filename,']','_'); % remove invalid chars from var name

            suffix = strrep(suffix,'-','_'); % remove invalid chars from var name
            suffix = strrep(suffix,' ','_'); % remove invalid chars from var name
            suffix = strrep(suffix,'[','_'); % remove invalid chars from var name
            suffix = strrep(suffix,']','_'); % remove invalid chars from var name

            new_var_name = sprintf('%s%s_traj',filename,suffix);

            if do_assign_in_base
                assignin('base',new_var_name,traj);
            end


        end
        
        
         % Loads a CSV file of trajectories that were produces using TrajFinder (C++ code).
        function traj = LoadLKFromCSV(traj_csv_filename)
            
            metadata = FPVUtils.ReadTrajFinderMeta(traj_csv_filename);

            lkcsv=csvread(traj_csv_filename,1,0);
            numFrames = size(lkcsv,1);
            xblocks = str2double(metadata('NUM_BLOCKS_X'));
            yblocks = str2double(metadata('NUM_BLOCKS_Y'));
            blockwidth = str2double(metadata('BLOCK_WIDTH'));
            blockheight = str2double(metadata('BLOCK_HEIGHT'));

            processing_width = str2double(metadata('PROCESSING_WIDTH'));
            processing_height = str2double(metadata('PROCESSING_HEIGHT'));

            numTrajs = xblocks*yblocks;
            sframe = str2double(metadata('START_FRAME'));
            eframe = str2double(metadata('END_FRAME'));
            skip = str2double(metadata('FRAME_SKIP'))+1;
            frame_range = sframe:skip:eframe;
            frame_range = frame_range(1:numFrames); 

            X = zeros(numTrajs,numFrames);
            Y = zeros(numTrajs,numFrames);
            tracking_valid = zeros(numTrajs,numFrames);
            cannysum = zeros(numTrajs,numFrames);
            fpcount = zeros(numTrajs,numFrames);
            backprojerr = zeros(numTrajs,numFrames);


            t=0;
            for yb=1:yblocks
                for xb=1:xblocks
                    t=t+1;

                    if mod(t,10)==0
                        fprintf('%sLoading trajectory %d/%d...\n',log_line_prefix,t,numTrajs);
                    end

                    % Each LK traj is composed of six elements: valid,x,y,sum_canny,num_fpoints,backproj_err. The valid
                    % vector is 0 if the result is invalid and 1 if it is valid.
                    ind = 1+(t-1)*6; % Ind to the first column of the current trajectory (Matlab is 1 based).

                    valid = lkcsv(:,ind);
                    x = lkcsv(:,ind+1);
                    y = lkcsv(:,ind+2);
                    traj_canny = lkcsv(:,ind+3);
                    traj_num_fpoints = lkcsv(:,ind+4);
                    traj_backproj_err = lkcsv(:,ind+5);


                    % suppress large motions that dont make sense
                    max_valid_x = min([blockwidth 50]);
                    max_valid_y = min([blockheight 50]);
                    valid = valid .* (abs(x)<max_valid_x);
                    valid = valid .* (abs(y)<max_valid_y);

                    % Need at least two points to interpolate missing data...
                    if sum(valid) > 2

                        % Set invalid points to nan
                        invalid_logical = valid==0;

                        if sum(invalid_logical)>0

                            x(invalid_logical) = interp1(frame_range(~invalid_logical),x(~invalid_logical),frame_range(invalid_logical));
                            y(invalid_logical) = interp1(frame_range(~invalid_logical),y(~invalid_logical),frame_range(invalid_logical));

                             % Handle nans on boundaries...
                            if isnan(x(1)) || isnan(x(end))
                                temp=find(~isnan(x));
                                if numel(temp)>0
                                    first_not_nan=temp(1);
                                    x(1:first_not_nan-1) = x(first_not_nan);
                                    y(1:first_not_nan-1) = y(first_not_nan);
                                    last_not_nan=temp(end);
                                    x(last_not_nan+1:end) = x(last_not_nan);
                                    y(last_not_nan+1:end) = y(last_not_nan);
                                else
                                    % Entire traj is nan??
                                end
                            end
                        end
                    else
                        % This trajectory is entirely invalid.
                        valid(:) = 0;
                        x(:) = 0;
                        y(:) = 0;
                    end

                    tracking_valid(t,:) = valid;
                    X(t,:) = x;
                    Y(t,:) = y;
                    cannysum(t,:) = traj_canny;
                    fpcount(t,:) = traj_num_fpoints;
                    backprojerr(t,:) = traj_backproj_err;

                end
            end

            traj.num_frames = numFrames;
            traj.width = processing_width;
            traj.height = processing_height;
            traj.num_x_cells = xblocks;
            traj.num_y_cells = yblocks;
            traj.skip = skip;
            traj.csv_fname = traj_csv_filename;
            traj.frame_range = frame_range;
            traj.num_trajs = numTrajs;
            traj.LK_X = X ./ traj.width; % Normalize to image size.
            traj.LK_Y = Y ./ traj.height;
            traj.LK_valid = tracking_valid;
            traj.cannysum = cannysum ./ (blockwidth*blockheight);
            traj.fpcount = fpcount ./ (blockwidth*blockheight);
            traj.backprojerr = backprojerr;
            traj.fps = str2double(metadata('FPS'));

        end


        function [metadata] = ReadTrajFinderMeta(traj_csv_filename)

            fileID = fopen(traj_csv_filename);
            line = textscan(fileID, '%s',1,'Delimiter','\n');
            fclose(fileID);

            line = cell2mat(line{1});
            [pairs] = textscan(line,'%s','Delimiter',',');

            metadata = containers.Map();

            for i=1:numel(pairs{1})
                [kvpair] = textscan(pairs{1}{i},'%s','Delimiter','=');
                metadata(kvpair{1}{1}) = kvpair{1}{2};
            end
        end
        
        
        function files = GetFileList(fname_mask)
            
            if ischar(fname_mask)
                % Convert to cell array.
                temp_fnamemask = fname_mask;
                fname_mask = cell(1,1);
                fname_mask{1} = temp_fnamemask;
            else
                if ~iscell(fname_mask)
                    error('fname_mask variable should be either string with file mask or a cell array of strings with file mask.');
                end
            end


            totalfiles = 0;
            flist=dir('');
            dirprefix_list = {};
            for i=1:numel(fname_mask)
                dirprefix = fileparts(fname_mask{i});
                templist = dir(fname_mask{i});

                for i=1:numel(templist)
                    if ~templist(i).isdir
                        flist(end+1) = templist(i);
                        dirprefix_list{end+1} = dirprefix;

                        totalfiles = totalfiles+1;
                    end
                end
            end


            fprintf('%sFound %d files.\n',log_line_prefix,numel(flist));
            files = {};
            
            for i=1:numel(flist)

                if ~flist(i).isdir
                    
                    files{end+1} = fullfile(dirprefix_list{i},flist(i).name);
                    
                end

            end
            
        end
    end
    
    
end