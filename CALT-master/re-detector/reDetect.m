 %% perform color score map for re-detection
[likelihood_map3] = getColourMap(im, bg_hist, fg_hist, p.n_bins, p.grayscale_sequence);
likelihood_map3 = (likelihood_map3 + min(likelihood_map3(:)))/(max(likelihood_map3(:)) + min(likelihood_map3(:)));
pos_center(1)=round(size(likelihood_map3,1)/2);
pos_center(2)=round(size(likelihood_map3,2)/2);
likelihood_map3(isnan(likelihood_map3)) = 0;
candidate_cf = getSubwindow(im,pos_color,p.norm_bg_area, bg_area); 
[response_temp_t, candidate_score_plus(1)] = confidenceCalculate(candidate_cf, p, hann_window, hf_num, hf_den,w2c);
 hogScore_temp(1) = calculatePSR(response_temp_t) ; 
 likelihood_map_center= getSubwindow(likelihood_map3,pos_color,target_sz);
 colorScore_temp(1)=calculateColor(likelihood_map_center);
 %% perform KF filters for re-detection
 context= generate_particles(pos_kf,target_sz,p);
 for j=1:size(context,2)
    candidate_cf =getSubwindow(im,context{j}.pos, p.norm_bg_area, bg_area);
     [response_temp{j}, candidate_score(j)] = confidenceCalculate(candidate_cf, p, hann_window, hf_num, hf_den,w2c);   
  end
      
 [~, ID] = max(candidate_score); 
 candidate_score_plus(2)=candidate_score(ID);
 hogScore_temp(2) = calculatePSR(response_temp{ID}) ; 
 pos3=context{ID}.pos;
  
 likelihood_map_center= getSubwindow(likelihood_map3,pos3,target_sz);
  colorScore_temp(2)=calculateColor(likelihood_map_center);
        
 %% perform repalcement check
 replace_allowed=0;
 if((candidate_score_plus(1))>(p.gamma_csm*(max(response_cf(:)))))&&( hogScore_temp(1)>=hog_high_thres * hogAver)&&( colorScore_temp(1)>=color_high_thres * colorAver)
  replace_allowed=1;
 end
 if((candidate_score_plus(2))>(p.gamma_kf*(max(response_cf(:)))))&&( hogScore_temp(2)>=hog_high_thres * hogAver)&&(colorScore_temp(2)>=color_high_thres * colorAver)
  replace_allowed=1;
 end
 if((candidate_score_plus(1)>candidate_score_plus(2))&&(replace_allowed==1))
  pos_rd=pos_color; 
 elseif ((candidate_score_plus(1)<=candidate_score_plus(2))&&replace_allowed==1)
  pos_rd=pos_kf;
 end
 
 