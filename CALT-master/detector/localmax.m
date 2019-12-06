function [r,c]=localmax(response_hog,response_pwp,maxvalue,p)
sz = size(response_hog);
rg = circshift(-floor((sz(1)-1)/2):ceil((sz(1)-1)/2), [0 0]);
cg = circshift(-floor((sz(2)-1)/2):ceil((sz(2)-1)/2), [0 0]);
[rs, cs] = ndgrid(rg,cg);
dist_param = max(sum(p.norm_target_sz)/2, 30);  
dist = sqrt((rs.^2 + cs.^2));
y = cosd((15*dist)/dist_param);
response_hog(response_hog<maxvalue*0.7)=0;
max_val1 = max(response_hog(:));
    if max_val1 <= 0
        max_val1 = 1.;
    end
response_hog = response_hog./max_val1;
max_val2 = max(response_pwp(:));
    if max_val2 <= 0
        max_val2 = 1.;
    end
response_pwp= response_pwp./max_val2;
[r3,c3] = find(response_pwp == max(response_pwp(:)));
response=response_hog+response_pwp;
response=response.*y;

[r2,c2] = find(response == max(response(:)));
if(numel(r2)==0)
    r=r3(1);
    c=c3(1);
else
   r=r2(1);
   c=c2(1);
end
end

