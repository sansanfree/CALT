
function [out_CN, out_HOG] = getFeatureMap(im_patch, cf_response_size, hog_cell_size, w2c)
% Extract HOG and ColorNames features

temp = fhog(single(im_patch), hog_cell_size);
h = cf_response_size(1);
w = cf_response_size(2);
out_HOG = zeros(h, w, 32, 'single');

out_HOG(:,:,2:32) = temp(:,:,1:31);

if hog_cell_size > 1
    im_patch = mexResize(im_patch, [h, w] ,'auto');
end

% if color image
if size(im_patch, 3) > 1
    im_patch_gray = rgb2gray(im_patch);
    out_CN = get_feature_map(im_patch, 'cn', w2c);
else
    im_patch_gray = im_patch;
    out_CN = temp;
end

out_HOG(:,:,1) = single(im_patch_gray)/255 - 0.5; 

end
