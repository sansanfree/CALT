function results = run_CALT(seq, res_path, bSaveImage)
% for OTB format

addpath('./re-detector');
addpath('./detector');    
addpath('./utility');

 params.img_files = seq.s_frames;
%% tracking-by-detection
params.grayscale_sequence = false;	       % suppose that sequence is colour
params.hog_cell_size = 4;
params.fixed_area = 150^2;                 % standard area to which we resize the target
params.n_bins = 2^5;                       % number of bins for the color histograms (bg and fg models)
params.learning_rate_pwp = 0.01;           % bg and fg color models learning rate 
params.inner_padding = 0.2;                % defines inner area used to sample colors from the foreground
params.out_padding =1.5; 
params.SSA_padding =0.0;  
params.search_padding =7;                
params.output_sigma_factor = 1/16;        % standard deviation for the desired translation filter output
params.lambda = 1e-3;                      % regularization weight
params.learning_rate_cf = 0.01;            % HOG model learning rate

%% unreliability and reliability check
params.color_low_thres = 0.4;
params.color_high_thres = 0.6;
params.hog_low_thres = 0.5;
params.hog_high_thres = 0.7;
%% scale related
params.hog_scale_cell_size = 4;            % from DSST 
params.learning_rate_scale = 0.025;
params.scale_sigma_factor = 1/2;
params.num_scales = 33;
params.scale_model_factor = 1.0;
params.scale_step = 1.02;
params.scale_model_max_area = 32*16;
params.numParticles=0;
params.gamma_csm=1.8;
params.gamma_kf=2;
%% debugging stuff 
params.visualization = 1;                 % show output bbox on frame
%% start trackerMain.m
im = imread(params.img_files{1});


% is a grayscale sequence ?
if(size(im,3)==1)
   params.grayscale_sequence = true;
else
   params.grayscale_sequence = false;
end
 params.img_path = '';

  x = seq.init_rect(1);
  y = seq.init_rect(2);
  w = seq.init_rect(3);
  h = seq.init_rect(4);
  cx = x+w/2;
  cy = y+h/2;
  % init_pos is the centre of the initial bounding box
  params.init_pos = [cy cx];
  params.target_sz = round([h w]);
 
 
[params, bg_area, fg_area,SSA_bg_area,area_resize_factor] = initializeAllAreas(im, params);

if params.visualization
    params.videoPlayer = vision.VideoPlayer('Position', [100 100 [size(im,2), size(im,1)]+30]);
end

results=trackerMain(params, im, bg_area, fg_area,SSA_bg_area, area_resize_factor);
end