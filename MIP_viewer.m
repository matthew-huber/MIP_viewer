clear all

%% NEED USER INPUTS

num_angles = 50;
depth_weighting = 0;
d = 3; % attenuation factor
%% Load Data

data = 'petimg.fl'
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


%% Read in CT Data
CT_data = 'ctimg.sh';
[fID, err] = fopen(CT_data);

read_data_CT = fread(fID, 'int16');
fclose(fID);

CT_frame_size=512;
CT_data = reshape(read_data_CT, CT_frame_size, CT_frame_size, []);

%downsample CT
%CT_data = CT_data(4:4:CT_frame_size, 4:4:CT_frame_size, :);
CT_data = imresize(CT_data, [frame_size, frame_size]);
CT_data = double(CT_data); % for the filtering
CT_data_orig = CT_data;
pd_size = 4;
CT_data = padarray(CT_data, [0,pd_size, 0], min(CT_data(:)), 'both');

for i = 1:size(CT_data, 3) % add blut filter
    CT_data(:, :, i) = colfilt(CT_data(:, :, i), [2,8],'sliding', @median);
end
CT_data = CT_data(:, (pd_size/2):(128+pd_size/2), :); % restore to normal size after padding

CT_data = CT_data - min(CT_data(:));

body_start_thresh = 2924;
min_thresh_len = 5; % number of consecutive samples above thresh to be considered part of body
%%

for slice_ix = 1:num_slices
    %CT_frame = CT_data(:, :, slice_ix);
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
        attenuation = dist_to_max .*exp(-d);
        M_attenuated = M .* attenuation;
        data_out_attn2(:,slice_ix,angle_ix) = M_attenuated;
        max_locs_attn2(:,slice_ix,angle_ix) = I;
        
        %         Alternative Attenuation method
        %         crop_rot_data = rot_data(ind1, ind1);
        %         attenuation = (size(crop_rot_data, 2):-1:1).*exp(-d);
        %         attenuation = repmat(attenuation, 128, 1)';
        %         crop_rot_data = crop_rot_data .*attenuation;
        %                 [M,I] = max(crop_rot_data,[],2);
        %         data_out_attn1(:,slice_ix,angle_ix) = M;
        %         max_locs_attn1(:,slice_ix,angle_ix) = I;
    end
    disp(slice_ix)
end

%% Visualize Rotation

for i = 1:num_angles
    subplot(121)
    imagesc(squeeze(data_out_orig(:,:,i))')
    colorbar
    caxis([0 5e4])
    title('Original')
    colormap gray
    subplot(122)
    imagesc(squeeze(data_out_attn2(:,:,i))')
    colorbar
    caxis([0 0.1e6])
    title('Attenuated')
    pause(0.1)
end


