clear;clc;
% close;

%This code solves the CH equation in 2D using the BHM method
dt =0.001; M1 =2; iter =1; tfinal =5; N=256; a=0; L=2; b=L*pi;
% number of grid points N uniform mesh thickness
h=(b-a)/N; n=N;
% xgrid formation (a b] and eventually (a b]^2
x=(a:h:b-h);x= gpuArray (x); 
[X,Y]= meshgrid (x,x);
k =[0: N/2 -N /2+1: -1]./(( L)/2); 
k= gpuArray(k);
[k1x k1y ]= meshgrid (k.^1,k.^1); 
[kx ky]= meshgrid (k.^2,k.^2);
k2=kx+ky; k4=k2.^2;

% parameters
epsilon =.05; eps2= epsilon^2; lhs =1+ dt*M1*k4*eps2; % CH lhs
it =0; j=0; nn =0; t=0.0; M=1; tsave = 0.1;

% Initial Condition ----------------------
rng(1,"philox");
U =0.01* rand(N,N) +.5*0; U= gpuArray (U);

figure(1); 
s=pcolor(X,Y,U);
s.FaceColor='interp';
s.EdgeColor='interp';


pcolor(X,Y,U);
shading interp;
axis off;
axis equal;

% figure(2);
ax = gca; ax.FontSize = 14;
hold on;


nplot = round((tfinal-t)/dt);
nsave = round(tsave/dt);

hat_U =fft2(U); 
for nt = 1:nplot
    U1=U;
    RHS=eps2 *(M1 -M)*ifft2(k4.* fft2(U1))+ifft2 (-1*k2.* fft2(U1.^3-U1));
    hat_rhs = hat_U + dt.* fft2(RHS);
    hat_U1 = hat_rhs ./ lhs; U1=real(ifft2( hat_U1 ));
    U=real(U1); hat_U= hat_U1 ; it=it +1; 
    
    t=t+dt; % update

    if  0 == mod(nt,nsave)
        t
        s=pcolor(X,Y,U);
        s.FaceColor='interp';
        s.EdgeColor='interp';
        colorbar;
        axis off;
        axis equal;
        title (['BHM method = ' num2str(t),' dt = ' num2str(dt)], 'FontSize' ,12);
        drawnow;
    end
end %main loop


% title (['BHM method = ' num2str(t),' dt = ' num2str(dt)], ...
%     'FontSize ' ,12);