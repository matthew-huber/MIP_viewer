function [region_start] = thresh_region(CT_line,thresh, N)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
BV = CT_line>thresh;
delta_line = diff(BV);
start_inx = find(delta_line==1);
end_inx = find(delta_line==-1);

if length(start_inx) > length(end_inx)
    start_inx = start_inx(1:end-1);
end
if length(end_inx) > length(start_inx)
    start_inx = [1 start_inx'];
end

    

region_lengths = end_inx - start_inx;

region_num = find(region_lengths>N, 1, 'first');

region_start = start_inx(region_num);
if isempty(region_start)
    region_start = 1;
end


end