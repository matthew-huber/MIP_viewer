data = 'phantompet15sec.fl'

%%

[fID, err] = fopen(data);

tmp = fread(fID, 'float32');
%%

tmp_2 = reshape(tmp,128, 128, 83);
figure(1)
for i = 1:size(tmp_2,3)
    for j = 1:size(tmp_2,4)
        imagesc(tmp_2(:,:,i,j))
        pause(0.05)
    end
end


