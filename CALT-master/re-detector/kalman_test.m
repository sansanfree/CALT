


x = A*x + B*u;
    % Estimate the error covariance 
    S = A*S*A' + Q;
    % Kalman Gain Calculations
    K = S*H'*inv(H*S*H'+R);

    % Update the estimation
    if(~isempty(input_pos)) %Check if we have an input
        x = x + K*(input_pos'- H*x);
    end
    % Update the error covariance
    S = (eye(size(S,1)) - K*H)*S;
    % Save the measurements for plotting
    Kalman_Output = H*x; 
    Kalman_Output=Kalman_Output';

