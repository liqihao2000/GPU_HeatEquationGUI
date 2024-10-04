function [t, U] = heateq_cpu_filt(k, n, Ts, L, c,h)
% HEATEQ_CPU_FILT Solves the 2D heat equation on the CPU using FILTER2
%
%    [t, U] = HEATEQ_CPU_FILT(k, n, Ts, L, c,h)  returns a matrix U representing 
%    the temperature at each row, column location.  The function discretizes a 
%    2D square plate of length L and thermal diffusivity c by using n 
%    points.  The function will perform k iterations using the timestep Ts.
%    h is the handles structure from heateqGUI
%
%    Example: Solve for the temperature on a 1 m -by- 1 m copper plate 
%    after 10 seconds have elapsed.  The thermal diffusivity of copper is:
%    1.13e-4 m^2/s
%
%    [t, U] = heateq_cpu_filt(3e4, 100, 1e-2, 1, 1.13e-4);
%
%    Copyright 2013 The MathWorks, Inc.

tic;

% Calculate the mesh spacing
ms = L / n;  

% Sanity Check: Ensure time step is small enough for stability
if Ts > 0.6*(ms^2/2/c)
    Ts = 0.6*(ms^2/2/c);
    warndlg(['Selected time step was too large and was changed to: ',num2str(Ts)]);
end

% Initialize the grid with starting temperatures
U = init_temp_distribution(n);

xy = linspace(0,1,n);
imagesc(xy, xy, U, 'Parent', h.axes1)
set(h.axes1, 'YDir', 'normal')
colorbar('peer', h.axes1)
set(h.axes1, 'NextPlot', 'ReplaceChildren')
set(h.tSimTime,'String','0')
drawnow

% set update rate
numUpdates = min(k, str2double(get(h.eNumUpdates,'String')));
updateIters = round((1:numUpdates)/numUpdates*k);
nextIter = 1;

% Calculate the coordinates for the neighboring grid points
current = 2:(n + 1);

f = [0 1 0; 1 -4 1; 0 1 0] * c*Ts/(ms^2) + [0 0 0; 0 1 0; 0 0 0];

for iter = 1:k
    U(current, current) = filter2(f, U, 'valid');

    if iter == updateIters(nextIter)
        imagesc(xy, xy, U, 'Parent', h.axes1)
        set(h.tSimTime,'String',num2str(iter*Ts, '%.1f'))
        nextIter = nextIter + 1;
    end
    drawnow
    if get(h.pbStartStop, 'Userdata') == 1
        set(h.pbStartStop, 'Userdata', 0)
        t = 0;
        return
    end
end

set(h.axes1, 'NextPlot', 'Replace')

t = toc;


function U = init_temp_distribution(n)

% Initialize each point on the grid to be at room temperature
U = 23*ones(n + 2);
T = 100;
% Create a temperature gradient at the boundary
U(1, :) = (1:(n + 2))*T/(n + 2);
U(end, :) = ((1:(n + 2)) + (n + 2))*T/2/(n + 2);
U(:, 1) = (1:(n + 2))*T/(n + 2);
U(:, end) = ((1:(n + 2)) + (n + 2))*T/2/(n + 2);