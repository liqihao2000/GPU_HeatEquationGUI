function varargout = heateqGUI(varargin)
% HEATEQGUI MATLAB code for heateqGUI.fig
%      HEATEQGUI, by itself, creates a new HEATEQGUI or raises the existing
%      singleton*.
%
%      H = HEATEQGUI returns the handle to a new HEATEQGUI or the handle to
%      the existing singleton*.
%
%      HEATEQGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HEATEQGUI.M with the given input arguments.
%
%      HEATEQGUI('Property','Value',...) creates a new HEATEQGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before heateqGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to heateqGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% Copyright 2013 The MathWorks, Inc

% Edit the above text to modify the response to help heateqGUI

% Last Modified by GUIDE v2.5 13-Feb-2013 16:11:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @heateqGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @heateqGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before heateqGUI is made visible.
function heateqGUI_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to heateqGUI (see VARARGIN)

% Choose default command line output for heateqGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
init_temp_distribution(handles);
updateFields(handles)

% UIWAIT makes heateqGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = heateqGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupImplement.
function popupImplement_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% hObject    handle to popupImplement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupImplement contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupImplement
set(handles.tTimeCPU,'String','0.0')
set(handles.tTimeGPU,'String','0.0')

% --- Executes during object creation, after setting all properties.
function popupImplement_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupImplement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pbStartStop.
function pbStartStop_Callback(hObject, eventdata, handles)
% hObject    handle to pbStartStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value')
    
    set(handles.pbStartStop, 'String', 'Stop');
    
    n = str2double(get(handles.eGridSize,'String'));
    k = str2double(get(handles.eIter,'String'));
    Ts = str2double(get(handles.eTs,'String'));
    L = 1;               % size of square plate
    c = 1.13e-4;         % thermal diffusivity of copper
    
    % Depending on selected implementation and device call correct function
    implIdx = get(handles.popupImplement,'Value');
    isGPU = get(handles.rbGPU,'Value');
    set(handles.figure1,'Pointer','watch');
    drawnow
    
    if implIdx == 1 && isGPU  % Filtering on GPU
        t = heateq_gpu_filt(k,n,Ts,L,c,handles);
        set(handles.tTimeGPU,'String',num2str(t,'%0.1f'))
    elseif implIdx == 1 && ~isGPU  % Filtering on CPU
        t = heateq_cpu_filt(k,n,Ts,L,c,handles);
        set(handles.tTimeCPU,'String',num2str(t,'%0.1f'))
    elseif implIdx == 2 && isGPU  % Indexing on GPU
        t = heateq_gpu_ind(k,n,Ts,L,c,handles);
        set(handles.tTimeGPU,'String',num2str(t,'%0.1f'))
    else  % Indexing on CPU
        t = heateq_cpu_ind(k,n,Ts,L,c,handles);
        set(handles.tTimeCPU,'String',num2str(t,'%0.1f'))
    end
    set(handles.figure1,'Pointer','Arrow')
    set(handles.pbStartStop,'Value',0)
    set(handles.pbStartStop,'String','Start')
    drawnow
      
    tcpu = str2double(get(handles.tTimeCPU,'String'));
    tgpu = str2double(get(handles.tTimeGPU,'String'));
    if tcpu > 0 && tgpu > 0
        msgbox(['GPU was ', num2str(tcpu/tgpu, '%.1f'),...
            'x faster than CPU.'], 'Speedup')
    end
else
    set(handles.pbStartStop, 'String', 'Start');
    set(handles.pbStartStop, 'UserData', 1)
end

function eGridSize_Callback(hObject, eventdata, handles)
% hObject    handle to eGridSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eGridSize as text
%        str2double(get(hObject,'String')) returns contents of eGridSize as a double
init_temp_distribution(handles);

updateFields(handles)

% --- Executes during object creation, after setting all properties.
function eGridSize_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to eGridSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eIter_Callback(hObject, eventdata, handles)
% hObject    handle to eIter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eIter as text
%        str2double(get(hObject,'String')) returns contents of eIter as a double


% --- Executes during object creation, after setting all properties.
function eIter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eIter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function eTs_Callback(hObject, eventdata, handles)
% hObject    handle to eTs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eTs as text
%        str2double(get(hObject,'String')) returns contents of eTs as a double


% --- Executes during object creation, after setting all properties.
function eTs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eTs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function init_temp_distribution(handles)
% Initialize each point on the grid to be at room temperature
n = str2double(get(handles.eGridSize,'String'));
U = 23*ones(n + 2);
T = 100;
% Create a temperature gradient at the boundary
U(1, :) = (1:(n + 2))*T/(n + 2);
U(end, :) = ((1:(n + 2)) + (n + 2))*T/2/(n + 2);
U(:, 1) = (1:(n + 2))*T/(n + 2);
U(:, end) = ((1:(n + 2)) + (n + 2))*T/2/(n + 2);

xy = linspace(0,1,n);
handles.imHandle = imagesc(xy, xy, U, 'Parent', handles.axes1);
set(handles.axes1, 'YDir', 'normal')
guidata(handles.figure1, handles)
colorbar

function eTotal_Callback(hObject, eventdata, handles)
% hObject    handle to eTotal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eTotal as text
%        str2double(get(hObject,'String')) returns contents of eTotal as a double

updateFields(handles)


% --- Executes during object creation, after setting all properties.
function eTotal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eTotal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function updateFields(handles)
n = str2double(get(handles.eGridSize,'String'));
T = str2double(get(handles.eTotal,'String'));
L = 1;               % size of square plate
c = 1.13e-4;         % thermal diffusivity of copper

ms = L / n;          % grid width
Ts = 0.5*(ms^2/2/c); % rough step size
k = ceil(T/Ts);      % number of steps
Ts = T/k;            % adjusted step size

set(handles.eTs,'String',num2str(Ts));
set(handles.eIter,'String',num2str(k));
set(handles.tTimeCPU,'String','0.0')
set(handles.tTimeGPU,'String','0.0')

function eNumUpdates_Callback(hObject, eventdata, handles)
% hObject    handle to eNumUpdates (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eNumUpdates as text
%        str2double(get(hObject,'String')) returns contents of eNumUpdates as a double
set(handles.tTimeCPU,'String','0.0')
set(handles.tTimeGPU,'String','0.0')


% --- Executes on button press in pbCodeComp.
function pbCodeComp_Callback(hObject, eventdata, handles)
% hObject    handle to pbCodeComp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
implIdx = get(handles.popupImplement,'Value');
if implIdx == 1 % Compare code for filtering
    visdiff('heateq_cpu_filt.m', 'heateq_gpu_filt.m');
else
    visdiff('heateq_cpu_ind.m', 'heateq_gpu_ind.m');
end
    
