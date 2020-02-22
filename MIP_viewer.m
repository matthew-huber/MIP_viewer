clear all

%% NEED USER INPUTS

num_angles = 50;
depth_weighting = 0;

%% Load Data

data = 'phantompet15sec.fl'
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


