
    dt=0.5;
    A = [1 0 dt 0;
         0 1 0 dt;
         0 0 1 0 ;
         0 0 0 1 ;
         ];
    B = [(dt^2)/2 (dt^2)/2 dt dt]';

    u = 4e-3;
    H = [1 0 0 0;
      0 1 0 0];
    State_Uncertainty = 10;
    S = State_Uncertainty * eye(size(A,1)); % The state variables are independet, so the covariance matrix is a diagonal matrix.
    % Defining the <Measurement Noise> Covariance Matrix R
    Meas_Unertainty = 1;
    R = Meas_Unertainty * eye(size(H,1));

    Dyn_Noise_Variance = (0.01)^2;
%Shahin = [(1/2)*(dt^2) (1/2)*(dt^2) dt dt 1 1]'; %Constant Acceleration
% Shahin = [(1/2)*(dt^2) (1/2)*(dt^2) dt dt]'; %Constant Velocity
%Q = Shahin*Shahin'*Dyn_Noise_Variance;
% Assuming the variables X and Y are independent
    Q = [(dt^2)/4 0 (dt^3)/2 0;
         0 (dt^2)/4 0 (dt^3)/2;
         (dt^3/2) 0 (dt^2) 0;
         0 (dt^3)/2 0 (dt^2);
         ];
x = [pos(1);pos(2); 0; 0;]; % Initial Values
Kalman_Output=[];