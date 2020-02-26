clear all

%% NEED USER INPUTS

disp('----------------------------------');
disp('Welcome to the MIP program!')
disp('Enter "exit" at any of the following prompts to quit the program\n')

data = input('Please enter the name of the PET data file for evaluation:\n','s')
num_angles = input('Please enter the number of angles to rotate:\n','s');
num_angles = str2num(num_angles);
depth_weighting = input('Please enter whether you would like depth weighting (Y/n):\n','s');

%% Load Data

%data = 'phantompet15sec.fl'
[fID, err] = fopen(data);

read_data = fread(fID, 'float32');
fclose(fID);

%% Reshape data and create matrices for output

frame_size = 128;

num_slices = length(read_data)/frame_size^2;

angles = linspace(0,360,num_angles+1);
angles = angles(1:end-1);

data_in = reshape(read_data,frame_size, frame_size, num_slices);
data_out = zeros(128,num_slices,num_angles);
max_locs = zeros(128,num_slices,num_angles);


%%

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
    disp(slice_ix)
end

%% Visualize Rotation

for i = 1:num_angles
    imagesc(squeeze(data_out(:,:,i)))
    colormap gray
    pause(0.1)
end

if depth_weighting == 'Y'

    %% Load CT Data

    CT_data = 'phantomct.sh'
    [fID, err] = fopen(CT_data);

    read_data_CT = fread(fID, 'float32');
    fclose(fID);

    %% Reshape data and create matrices for output

    frame_size_CT = 512;
    num_slices_CT = length(read_data_CT)/frame_size_CT^2;
    % WHY IS NUM SLICES CT NOT AN INTEGER????!???!?!!?

    CT_data = reshape(read_data_CT,frame_size_CT, frame_size_CT, num_slices_CT);

    %downsample CT 
    CT_data = CT_data(1:4:frame_size_CT,1:4:frame_size_CT,:);

    % hold body start position here, compare with max_locs to find distance for
    % attenuation
    body_start = zeros(128,num_slices,num_angles);
    
end



