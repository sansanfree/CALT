function [response_cf, score] = confidenceCalculate( candidate_cf,p, hann_window_cosine, hf_num, hf_den,w2c)
%UNTITLED2 Summary of this function goes here
[xt_CN, xt_HOG] = getFeatureMap(candidate_cf, p.cf_response_size, p.hog_cell_size,w2c);
xt = cat(3 ,xt_CN, xt_HOG);
% apply Hann window
xt_windowed = bsxfun(@times, hann_window_cosine, xt);
xtf = fft2(xt_windowed);
hf = bsxfun(@rdivide, hf_num, sum(hf_den, 3)+p.lambda);



response_cf = real(ifft2(sum(conj(hf) .* xtf, 3)));
% Crop square search region (in feature pixels).
response_cf = cropFilterResponse(response_cf, floor_odd(p.norm_delta_area / p.hog_cell_size));
score = max(response_cf(:));
if p.hog_cell_size > 1 
    % Scale up to match center likelihood resolution.
   response_cf = mexResize(response_cf, p.norm_delta_area,'auto');
end
end
% We want odd regions so that the central pixel can be exact
function y = floor_odd(x)
    y = 2*floor((x-1) / 2) + 1;
end


