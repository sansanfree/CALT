function [E]=edges_detect(I,likelihood_map,target_sz)
if(size(I,3)==1)
    I=cat(3,I,I,I);
end
% if(size(I,3)==3)
%       im= rgb2gray(I);
% end
global model;
 E=edgesDetect(I,model);
%  contour = edge(im ,'sobel');
E=E.*likelihood_map;
E = (E + min(E(:)))/(max(E(:)) + min(E(:)));  
center_likelihood =getLikelihood(E, target_sz);
[row, col] = find(center_likelihood == max(center_likelihood(:)), 1);

%center_location=round([row,col]+0.5*(target_sz)-0.5*size(likelihood_map))
% figure(5);% imshow(E);    

