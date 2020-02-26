clear all

%% Request User Inputs

disp('----------------------------------');
disp('Welcome to the MIP program!')
disp('Enter "exit" at any of the following prompts to quit the program')

valid_file = 0;

while valid_file == 0
    data = input('Please enter the name of the PET data file for evaluation:\n','s');

    if strcmp(data,'exit')
        disp('Exiting Program')
        exit;
    else
        [fID, err] = fopen(data);
        
        if ~strcmp(err,'')
            disp('Error opening file. Please Try again')
        else
            disp('Successfully opened file!')
            disp('')
            read_data = fread(fID, 'float32');
            fclose(fID);
            valid_file = 1;
        end
    end
end
if strcmp(data,'exit')
    disp('Exiting Program')
    exit;
end

num_angles = input('Please enter the number of angles to rotate:\n','s');
if strcmp(num_angles,'exit')
    disp('Exiting Program')
    exit;
end
num_angles = str2num(num_angles);

depth_weighting = input('Please enter whether you would like depth weighting (Y/N):\n','s');
if strcmp(depth_weighting,'exit')
    disp('Exiting Program')
    exit;
end

if strcmp(depth_weighting,'Y')
    d = input('Please enter the attenuation factor:\n','s');
    if strcmp(d,'exit')
        disp('Exiting Program')
        exit;
    end
    d = str2num(d);
end

file_out = input('Please enter the name of the file to output data to\n','s');

%% Reshape data and create matrices for output

frame_size = 128;

num_slices = length(read_data)/frame_size^2;

angles = linspace(0,360,num_angles+1);
angles = angles(1:end-1);

data_in = reshape(read_data,frame_size, frame_size, num_slices);
data_out = zeros(128,num_slices,num_angles);
max_locs = zeros(128,num_slices,num_angles);

%% Create MIP for different angles

disp('Generating maximum intensity projection')

if depth_weighting ~= 'Y'
    for slice_ix = 1:num_slices
        for angle_ix = 1:num_angles
            angle = angles(angle_ix);
            rot_data = imrotate(data_in(:,:,slice_ix),angle);

            i1 = round((size(rot_data, 1) - frame_size)/2);
            ind1 = i1+1:i1+frame_size;
            crop_rot_data = rot_data(ind1, ind1);

            [M,I] = max(crop_rot_data,[],2);
            data_out(:,slice_ix,angle_ix) = M;
            max_locs(:,slice_ix,angle_ix) = I;
         end
    end

else
    %% Load CT Data
    
    valid_file = 0;

    while valid_file == 0
        CT_data_file = input('Please enter the name of the CT data file for depth weighting:\n','s');

        if strcmp(CT_data_file,'exit')
            disp('Exiting Program')
            exit;
        else
            [fID, err] = fopen(CT_data_file);

            if ~strcmp(err,'')
                disp('Error opening file. Please Try again')
            else
                disp('Successfully opened file!')
                CT_data = fread(fID, 'int16');
                fclose(fID);
                valid_file = 1;
            end
        end
    end
    
    CT_frame_size=512;
    CT_data = reshape(CT_data, CT_frame_size, CT_frame_size, []);

    %downsample CT
    CT_data = imresize(CT_data, [frame_size, frame_size]);
    CT_data = double(CT_data); % for the filtering
    CT_data_orig = CT_data;
    pd_size = 4;
    CT_data = padarray(CT_data, [0,pd_size, 0], min(CT_data(:)), 'both');

    for i = 1:size(CT_data, 3) % add blur filter
        CT_data(:, :, i) = colfilt(CT_data(:, :, i), [2,8],'sliding', @median);
    end
    CT_data = CT_data(:, (pd_size/2):(128+pd_size/2), :); % restore to normal size after padding

    CT_data = CT_data - min(CT_data(:));

    body_start_thresh = 2924;
    min_thresh_len = 5; % number of consecutive samples above thresh to be considered part of body

    for slice_ix = 1:num_slices
        for angle_ix = 1:num_angles
            angle = angles(angle_ix);
            rot_data = imrotate(data_in(:,:,slice_ix),angle);
            CT_rot_data = imrotate(CT_data(:, :, slice_ix), angle);
            i1 = round((size(rot_data, 1) - frame_size)/2);
            ind1 = i1+1:i1+frame_size;
            crop_rot_data = rot_data(ind1, ind1);
            CT_rot_data = CT_rot_data(ind1, ind1);
            body_start_inx = zeros(1, size(CT_rot_data, 2));
            for j = 1:size(CT_rot_data, 2)
                CT_line = CT_rot_data(:, j);
                body_start_inx(j) = thresh_region(CT_line, body_start_thresh, min_thresh_len);
            end


            crop_rot_data_orig = crop_rot_data;

            [M,I] = max(crop_rot_data,[],1);
            data_out_orig(:,slice_ix,angle_ix) = M;
            max_locs_orig(:,slice_ix,angle_ix) = I;

            dist_to_max = I - body_start_inx;
            dist_to_max(dist_to_max<0)=0;
            attenuation = exp(-dist_to_max .*d);
            M_attenuated = M .* attenuation;
            data_out(:,slice_ix,angle_ix) = M_attenuated;
            max_locs_attn2(:,slice_ix,angle_ix) = I;

        end
        disp(slice_ix)
    end
end


%% Output matrix 

if strcmp(file_out,'exit')
    disp('Exiting Program')
    exit;
end

file_out = split(file_out,'.');
file_out = file_out{1};

% Visualize Rotation as a gif
time_per_angle = 5/num_angles; % make complete rotation take 5 seconds

sorted_data_out = sort(data_out(:));
data_ix = round(0.95*length(sorted_data_out));

h = figure;
axis tight manual
filename = [file_out '.gif'];
for i = 1:num_angles
    imagesc(squeeze(data_out(:,:,i)))
    caxis([0 sorted_data_out(data_ix)])
    colormap gray
    
    frame = getframe(h); 
    im = frame2im(frame); 
    [imind,cm] = rgb2ind(im,256); 
    % Write to the GIF File 
    if i == 1 
      imwrite(imind,cm,filename,'gif', 'Loopcount',inf,'DelayTime',time_per_angle); 
    else 
      imwrite(imind,cm,filename,'gif','WriteMode','append','DelayTime',time_per_angle); 
    end 
        
end

data_out = data_out(:);


