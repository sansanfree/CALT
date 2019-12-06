function  positive_ratio = calculateColor(likelihood_map)
binary_threshold=0.7;
positive_number=0;
[M,N]=size(likelihood_map);
for i=1:M
    for j=1:N
        if(likelihood_map(i,j)>binary_threshold)
         positive_number= positive_number+1;
        end
    end   
end
positive_ratio= positive_number/M/N*100;
end