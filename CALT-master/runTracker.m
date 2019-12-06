clear all;
% RUN_TRACKER  is the external function of the tracker - does initialization and calls trackerMain
%% path
addpath('./re-detector');
addpath('./detector');    
addpath('./utility');
%% load video info
videoname = 'Busstation_ce1'; 
base_path = './sequence/';
%base_path = 'F:\datasets\Temple-color-128\';
img_path= [base_path, videoname '\img\'];
[img_files, pos, target_sz, ground_truth,video_path] = load_video_info(base_path,videoname);
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
%% since the implement of color score is different from paper, so that params.color_low_thres and params.color_high_thres are different from paper.
params.color_low_thres = 0.4;
params.color_high_thres = 0.6;
params.hog_low_thres = 0.5;
params.hog_high_thres = 0.7;
%% scale related, which from from DSST 
params.hog_scale_cell_size = 4;            
params.learning_rate_scale = 0.025;
params.scale_sigma_factor = 1/2;
params.num_scales = 33;
params.scale_model_factor = 1.0;
params.scale_step = 1.02;
params.scale_model_max_area = 32*16;
%% related re-detection module
params.numParticles=0;
params.gamma_csm=1.8;
params.gamma_kf=2;
params.videoname=videoname;
%% visualization
params.visualization = 1;                 % show output bbox on frame

%% start trackerMain.m

im = imread([img_path img_files{1}]);

% is a grayscale sequence ?
if(size(im,3)==1)
   params.grayscale_sequence = true;
else
   params.grayscale_sequence = false;
end

params.img_files = img_files;
params.img_path = img_path;
% init_pos is the centre of the initial bounding box
params.init_pos = pos;
params.target_sz = target_sz;
[params, bg_area, fg_area,SSA_bg_area,area_resize_factor] = initializeAllAreas(im, params);

if params.visualization
    params.videoPlayer = vision.VideoPlayer('Position', [100 100 [size(im,2), size(im,1)]+30]);
end

% start the actual tracking
results=trackerMain(params, im, bg_area, fg_area,SSA_bg_area, area_resize_factor);
pd_boxes = results.res;
result_fps=results.fps;
%% evaluate the tracking result by AUC score
thresholdSetOverlap = 0: 0.05 : 1;
success_num_overlap = zeros(1, numel(thresholdSetOverlap));
res = calcRectInt(ground_truth, pd_boxes);
for t = 1: length(thresholdSetOverlap)
    success_num_overlap(1, t) = sum(res > thresholdSetOverlap(t));
end

cur_AUC = mean(success_num_overlap) / size(ground_truth, 1);
display([videoname  '---->'   '    AUC:   '   num2str(cur_AUC) '    fps:   '   num2str(result_fps)]);