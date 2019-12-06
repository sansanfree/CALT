% function: simulating the process of EKF
N = 50;           % ��������N��ʱ��
n = 3;             % ״̬ά��
q = 0.1;          % ���̱�׼��
r = 0.2;           % ������׼��
% eye����������λ����
Q = q^2*eye(n);   % ���̷���
R = r^2;               % ����ֵ�ķ���
 
%{
     FUNHANDLE = @FUNCTION_NAME returns a handle to the named function,
     FUNCTION_NAME. A function handle is a MATLAB value that provides a
     means of calling a function indirectly. 
%}
f = @(x)[x(2);x(3);0.05*x(1)*(x(2)+x(3))];  % ״̬����
h = @(x)[x(1);x(2);x(3)];                          % ��������
s = [0;0;1];                                            % ��ʼ״̬
 
% ��ʼ��״̬
x = s+q*randn(3,1); 
% eye���ص�λ����
P = eye(n);
% 3��50�У�һ�д���һ������
% ���Ź���ֵ
xV = zeros(n,N);
% ��ʵֵ
sV = zeros(n,N);
% ״̬����ֵ
zV = zeros(n,N);
 
for k = 1:N
    z = h(s) + r * randn;
    % ʵ��״̬
    sV(:,k) = s;
    % ״̬����ֵ
    zV(:,k) = z;
    
    % ����f���ſɱȾ�������x1��Ӧ�ƽ�ʽline2
    [x1,A] = jaccsd(f,x);
    % ���̷���Ԥ�⣬��Ӧline3
    P = A*P*A'+Q;
    % ����h���ſɱȾ���
    [z1,H] = jaccsd(h,x1);
    
    % ���������棬��Ӧline4
    % inv���������
    K = P*H'*inv(H*P*H'+R);
    % ״̬EKF����ֵ����Ӧline5
    x = x1+K*(z-z1);
    % EKF�����Ӧline6
    P = P-K*H*P;
    
    % save
    xV(:,k) = x;
    % update process 
    s = f(s) + q*randn(3,1);
end
for k = 1:3
    FontSize = 14;
    LineWidth = 1;
    
    figure();
    % ������ʵֵ
    plot(sV(k,:),'g-');
    hold on;
    
    % �������Ź���ֵ
    plot(xV(k,:),'b-','LineWidth',LineWidth);
    hold on;
    
    % ����״̬����ֵ
    plot(zV(k,:),'k+');
    hold on;
    
    legend('��ʵ״̬', 'EKF���Ź��ƹ���ֵ','״̬����ֵ');
    xl = xlabel('ʱ��(����)');
    % ����ֵת�����ַ����� ת�������ʹ��fprintf��disp�������������
    t = ['״̬ ',num2str(k)] ;
    yl = ylabel(t);
    set(xl,'fontsize',FontSize);
    set(yl,'fontsize',FontSize);
    hold off;
    set(gca,'FontSize',FontSize);
end

