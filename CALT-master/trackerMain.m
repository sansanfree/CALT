function [results] = trackerMain(p, im, bg_area, fg_area,SSA_bg_area,area_resize_factor)
% The main framework is obtained from Staple and MCCT-H
% Setup detector and re-detector
setupDetector;
bool_good=1;
temp = load('w2crs');
w2c = temp.w2crs;
output_rect_positions(num_frames, 4) = 0;
replace_allowed=0;
edges_init;
% Main Loop
tic;
for frame = 1:num_frames
if frame > 1
     
     im = imread([p.img_path p.img_files{frame}]); 
    im_patch_cf = getSubwindow(im, pos, p.norm_bg_area, bg_area);
    pwp_search_area = round(p.norm_pwp_search_area /area_resize_factor);
       % extract patch of size pwp_search_area and resize to norm_pwp_search_area
     im_patch_pwp = getSubwindow(im, pos, p.norm_pwp_search_area, pwp_search_area);
     [likelihood_map] = getColourMap(im_patch_pwp, bg_hist, fg_hist, p.n_bins, p.grayscale_sequence);
     likelihood_map(isnan(likelihood_map)) = 0;
     response_pwp = getCenterLikelihood(likelihood_map,p.norm_target_sz);
     likelihood_map = imResample(likelihood_map, p.cf_response_size);   
       % likelihood_map normalization, and avoid too many zero values
     likelihood_map = (likelihood_map + min(likelihood_map(:)))/(max(likelihood_map(:)) + min(likelihood_map(:)));  
     if(sum(likelihood_map(:))/prod(p.cf_response_size)<0.01), likelihood_map = 1; end    
     likelihood_map = max(likelihood_map, 0.1);
     center_location=floor(p.cf_response_size/2);
     likelihood_map_center= getSubwindow(likelihood_map,center_location,floor(target_sz/4*area_resize_factor),floor(target_sz/4*area_resize_factor));
  
   %% Contour-aware Response Generation
    im_patch_real_bg=zeros(bg_area);
    im_patch_target=getSubwindow(im,pos,SSA_bg_area,SSA_bg_area);
    [likelihood_contour_map] = getColourMap(im_patch_target, bg_hist, fg_hist, p.n_bins, p.grayscale_sequence);
    likelihood_contour_map = (likelihood_contour_map + min(likelihood_contour_map(:)))/(max(likelihood_contour_map(:)) + min(likelihood_contour_map(:)));  
    likelihood_contour_map(isnan(likelihood_contour_map)) = 0;
    if(p.grayscale_sequence ==false)
    [likelihood_map_SSA]=edges_detect(im_patch_target,likelihood_contour_map,target_sz);
    xs = round(bg_area(2)*0.5 + (1:SSA_bg_area(2)) -SSA_bg_area(2)/2);
    ys = round(bg_area(1)*0.5 + (1:SSA_bg_area(1)) -SSA_bg_area(1)/2);
    xs(xs < 1) = 1;
    ys(ys < 1) = 1;
    xs(xs > size(im,2)) = size(im,2);
    ys(ys > size(im,1)) = size(im,1);
    im_patch_real_bg(ys, xs,:)=likelihood_map_SSA;
    im_patch_real_bg = mexResize(im_patch_real_bg,p.norm_pwp_search_area,'auto'); 
    im_patch_real_bg(isnan(im_patch_real_bg)) = 0;
    response_contour = getLikelihood(im_patch_real_bg, p.norm_target_sz);
     
    end
    %% Estimation
    hann_window =hann_window_cosine.*likelihood_map; 
    % compute feature map
    [xt_CN, xt_HOG] = getFeatureMap(im_patch_cf, p.cf_response_size, p.hog_cell_size,w2c);
     xt = cat(3,xt_CN, xt_HOG);
     % apply Hann window
     xt_windowed= bsxfun(@times, hann_window, xt);
     xtf = fft2(xt_windowed);
     % Correlation between filter and test patch gives the response
     hf = bsxfun(@rdivide, hf_num, sum(hf_den, 3) + p.lambda);
     response_cf = real(ifft2(sum(conj(hf) .* xtf, 3))); 
      % Crop square search region (in feature pixels).
     response_cf = cropFilterResponse(response_cf, floor_odd(p.norm_delta_area / p.hog_cell_size));
     if p.hog_cell_size > 1
       % Scale up to match center likelihood resolution.
         response_cf = mexResize(response_cf, p.norm_delta_area,'auto');
     end 
      if(p.grayscale_sequence ==false)
         response =response_cf+response_contour;
      else
         response =response_cf;
      end
      size_response_cf=size(response_cf);
     %%  calculate HOGScore and ColorScore
       hogScore = calculatePSR(response_cf) ;           % hogScore
       colorScore=calculateColor(likelihood_map_center); 
       adaptiveUpdate;
       reshape_response = reshape(response.',size_response_cf(1)*size_response_cf(2),1);
       C=sort(reshape_response,'descend');
       [row1, col1] = find(response == C(1), 1);
      if(numel(row1)==0)
         row1=0;
         col1=0;
      end
       center = (1 + p.norm_delta_area)/2;
       
    %% "Unreliability" and "Reliability" check
       % Unreliability check 
      if(hogScore < hog_low_thres * hogAver )||( colorScore <color_low_thres * colorAver)    
     %% united location
      [row2, col2]=localmax(response_cf,response_pwp,max(response_cf(:)),p);
      row=row2;
      col=col2;  
      disp( [num2str(frame),'th Frame. Searching if there exists a better choice.']); 
      %% generate color score map for re-detection
       avg_dim = sum(target_sz)/2;
       search_area = round(target_sz+avg_dim*p.search_padding);
       if(search_area(2)>size(im,2)),  search_area(2)=size(im,2)-1;    end
       if(search_area(1)>size(im,1)),  search_area(1)=size(im,1)-1;    end
       search_area = search_area - mod(search_area - target_sz, 2);
       im_patch_search= getSubwindow(im,pos_prev,search_area,search_area);
       [likelihood_search_map] = getColourMap(im_patch_search, bg_hist, fg_hist, p.n_bins, p.grayscale_sequence);
       likelihood_search_map = (likelihood_search_map + min(likelihood_search_map(:)))/(max(likelihood_search_map(:)) + min(likelihood_search_map(:)));  
       likelihood_search_map(isnan(likelihood_search_map)) = 0;
       response_pwp1 = getCenterLikelihood(likelihood_search_map,target_sz);       
       [row3, col3] = find(response_pwp1 == max(response_pwp1(:)), 1);
       row4=row3+0.5*target_sz(1)-0.5*search_area(1);
       col4=col3+0.5*target_sz(2)-0.5*search_area(2);
       pos_color=pos_prev+[row4,col4];
      %% perform re-detction
       reDetect;
      else
      % adopt original tracking result by tracking-by-detection
      row=row1(1);
      col=col1(1);   
      pos_prev = pos;
      end 
     if(numel(row)==0)
         row=0;
         col=0;
     end 
     %% check whether peform repalcement
      if replace_allowed==0
      pos = pos + ([row, col] - center)/area_resize_factor;
      else
      pos = pos_rd;
      end
      replace_allowed=0;
   %  center_location
      rect_position = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
      %% SCALE SPACE SEARCH
       im_patch_scale = getScaleSubwindow(im, pos, base_target_sz, scale_factor*scale_factors, scale_window, scale_model_sz, p.hog_scale_cell_size,w2c);
        xsf = fft(im_patch_scale,[],2);
        scale_response = real(ifft(sum(sf_num .* xsf, 1) ./ (sf_den + p.lambda) ));
        recovered_scale = ind2sub(size(scale_response),find(scale_response == max(scale_response(:)), 1));
        %set the scale
        scale_factor = scale_factor * scale_factors(recovered_scale);

        if scale_factor < min_scale_factor
            scale_factor = min_scale_factor;
        elseif scale_factor > max_scale_factor
            scale_factor = max_scale_factor;
        end
        % use new scale to update bboxes for target, filter, bg and fg models
        target_sz = round(base_target_sz * scale_factor);
        avg_dim = sum(target_sz)/2;
        bg_area = round(target_sz + avg_dim*p.out_padding);
        SSA_bg_area= round(target_sz);
        if(bg_area(2)>size(im,2)),  bg_area(2)=size(im,2)-1;    end
        if(bg_area(1)>size(im,1)),  bg_area(1)=size(im,1)-1;    end
        if(SSA_bg_area(2)>size(im,2)), SSA_bg_area(2)=size(im,2)-1; end
	    if(SSA_bg_area(1)>size(im,1)), SSA_bg_area(1)=size(im,1)-1; end
        bg_area = bg_area - mod(bg_area - target_sz, 2);
        fg_area = round(target_sz - avg_dim * p.inner_padding);
        fg_area = fg_area + mod(bg_area - fg_area, 2);
        % Compute the rectangle with (or close to) params.fixed_area and same aspect ratio as the target bboxgetScaleSubwindow
        area_resize_factor = sqrt(p.fixed_area/prod(bg_area));

end
   
   %% TRAINING
    % extract patch of size bg_area and resize to norm_bg_area
    im_patch_bg = getSubwindow(im, pos, p.norm_bg_area, bg_area);
    % compute feature map, of cf_response_size
    [xt_CN, xt_HOG] = getFeatureMap(im_patch_bg, p.cf_response_size, p.hog_cell_size,w2c);
    xt = cat(3 ,xt_CN, xt_HOG);
    % apply Hann window
    if frame==1
    xt = bsxfun(@times, hann_window_cosine, xt);
    else
    xt = bsxfun(@times, hann_window, xt);
  
    end
    % compute FFT
    xtf = fft2(xt);
    % FILTER UPDATE
    % Compute expectations over circular shifts, therefore divide by number of pixels.
    new_hf_num = bsxfun(@times, conj(yf), xtf) / prod(p.cf_response_size);
    new_hf_den = (conj(xtf) .* xtf) / prod(p.cf_response_size);   
    if frame == 1
        % first frame, train with a single image
        hf_den = new_hf_den;
        hf_num = new_hf_num;
    else

        hf_den = (1 - p.learning_rate_cf) * hf_den + p.learning_rate_cf * new_hf_den;
        hf_num = (1 - p.learning_rate_cf) * hf_num + p.learning_rate_cf * new_hf_num;
        % BG/FG MODEL UPDATE   patch of the target + padding
        [bg_hist, fg_hist] = updateHistModel(new_pwp_model, im_patch_bg, bg_area, fg_area, target_sz, p.norm_bg_area, p.n_bins, p.grayscale_sequence, bg_hist, fg_hist, p.learning_rate_pwp);
        % update positive and negative templates every 5 frames   
    end
    
   %% SCALE UPDATE
    im_patch_scale = getScaleSubwindow(im, pos, base_target_sz, scale_factor*scale_factors, scale_window, scale_model_sz, p.hog_scale_cell_size,w2c);
    xsf = fft(im_patch_scale,[],2);
    new_sf_num = bsxfun(@times, ysf, conj(xsf));
    new_sf_den = sum(xsf .* conj(xsf), 1);
    if frame == 1,
        sf_den = new_sf_den;
        sf_num = new_sf_num;
    else
        sf_den = (1 - p.learning_rate_scale) * sf_den + p.learning_rate_scale * new_sf_den;
        sf_num = (1 - p.learning_rate_scale) * sf_num + p.learning_rate_scale * new_sf_num;
    end
    
    % update KF filters
    if frame==1
      rect_position = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
      kalman_init;
      pos_prev=pos;
    else
        if bool_good==1
            input_pos=pos;
        else
            input_pos=pos_kf;
        end
    kalman_test; 
    pos_kf=Kalman_Output;
   % rect_position2= [pos1([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
    end 
    rect_position_padded = [pos([2,1]) - bg_area([2,1])/2, bg_area([2,1])]; 
    output_rect_positions(frame,:) = rect_position;
   
   %% VISUALIZATION
    if p.visualization == 1
        if isToolboxAvailable('Computer Vision System Toolbox')
            im = insertShape(im, 'Rectangle', rect_position, 'LineWidth', 2, 'Color', 'red');
            im = insertShape(im, 'Rectangle', rect_position_padded, 'LineWidth', 2, 'Color', 'yellow');
            % Display the annotated video frame using the video player object.
            step(p.videoPlayer, im);
       else
            figure(1)
            imshow(im)
            rectangle('Position',rect_position, 'LineWidth',2, 'EdgeColor','r');
            rectangle('Position',rect_position_padded, 'LineWidth',2, 'LineStyle','-', 'EdgeColor','y');
            drawnow
       end
    end
end
 elapsed_time = toc; 
%  elapsed_time
results.type = 'rect';
results.res = output_rect_positions;
fps = num_frames/elapsed_time;
results.fps=fps;
end

% We want odd regions so that the central pixel can be exact
function y = floor_odd(x)
    y = 2*floor((x-1) / 2) + 1;
end


