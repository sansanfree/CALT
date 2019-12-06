function [params, bg_area, fg_area, SSA_bg_area,area_resize_factor] = initializeAllAreas(im, params)

	% we want a regular frame surrounding the object
	avg_dim = sum(params.target_sz)/2;
    params.avg_dim = avg_dim;
	% size from which we extract features
	bg_area = round(params.target_sz + avg_dim*params.out_padding);
    SSA_bg_area=round(params.target_sz + avg_dim*params.SSA_padding);
    search_area=round(params.target_sz + avg_dim*params.search_padding);
	% pick a "safe" region smaller than bbox to avoid mislabeling
	fg_area = round(params.target_sz - avg_dim * params.inner_padding);
	% saturate to image size
	if(bg_area(2)>size(im,2)), bg_area(2)=size(im,2)-1; end
	if(bg_area(1)>size(im,1)), bg_area(1)=size(im,1)-1; end
    if(SSA_bg_area(2)>size(im,2)), SSA_bg_area(2)=size(im,2)-1; end
	if(SSA_bg_area(1)>size(im,1)), SSA_bg_area(1)=size(im,1)-1; end
    if( search_area(2)>size(im,2)), search_area(2)=size(im,2)-1; end
	if( search_area(1)>size(im,1)), search_area(1)=size(im,1)-1; end
	% make sure the differences are a multiple of 2 (makes things easier later in color histograms)
	bg_area = bg_area - mod(bg_area - params.target_sz, 2);
    SSA_bg_area = SSA_bg_area - mod(SSA_bg_area - params.target_sz, 2);
    search_area = search_area - mod(search_area - params.target_sz, 2);
	fg_area = fg_area + mod(bg_area - fg_area, 2);

	% Compute the rectangle with (or close to) params.fixedArea and
	% same aspect ratio as the target bbox
	area_resize_factor = sqrt(params.fixed_area/prod(bg_area));
	params.norm_bg_area = round(bg_area * area_resize_factor);
    params.norm_search_area = round(search_area * area_resize_factor);
    params.norm_target_area = round(params.target_sz * area_resize_factor);
    params.norm_target_area = floor(params.norm_target_area/params.hog_cell_size);
	% Correlation Filter (HOG) feature space
	% It smaller that the norm bg area if HOG cell size is > 1
	params.cf_response_size = floor(params.norm_bg_area / params.hog_cell_size);
	% given the norm BG area, which is the corresponding target w and h?
 	norm_target_sz_w = 0.75*params.norm_bg_area(2) - 0.25*params.norm_bg_area(1);
 	norm_target_sz_h = 0.75*params.norm_bg_area(1) - 0.25*params.norm_bg_area(2);
%      norm_target_sz_w = params.target_sz(2) * params.norm_bg_area(2) / bg_area(2);
%  	norm_target_sz_h = params.target_sz(1) * params.norm_bg_area(1) / bg_area(1);
    params.norm_target_sz = round([norm_target_sz_h norm_target_sz_w]);
    norm_target_sz_w_1 = params.target_sz(2) * params.norm_bg_area(2) / bg_area(2);
	norm_target_sz_h_1 = params.target_sz(1) * params.norm_bg_area(1) / bg_area(1);
    params.norm_target_sz_plus = round([norm_target_sz_h_1 norm_target_sz_w_1]);
	% distance (on one side) between target and bg area
	norm_pad = floor((params.norm_bg_area - params.norm_target_sz) / 2);
	radius = min(norm_pad);
	% norm_delta_area is the number of rectangles that are considered.
	% it is the "sampling space" and the dimension of the final merged resposne
	% it is squared to not privilege any particular direction
	params.norm_delta_area = (2*radius+1) * [1, 1];
	% Rectangle in which the integral images are computed.
	% Grid of rectangles ( each of size norm_target_sz) has size norm_delta_area.
	params.norm_pwp_search_area = params.norm_target_sz + params.norm_delta_area - 1;
    params.radius=radius;
end
