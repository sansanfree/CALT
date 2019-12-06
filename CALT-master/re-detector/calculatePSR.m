function hogScore = calculatePSR(response_cf)
    cf_max = max(response_cf(:));
    cf_average = mean(response_cf(:));
    cf_sigma = sqrt(var(response_cf(:)));
    hogScore = (cf_max - cf_average)/cf_sigma;
end
