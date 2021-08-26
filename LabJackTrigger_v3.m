function LabJackTrigger_v3()
%This function generates commands for the LabJack U3-LV, to produce TTL
%pulses to trigger Mightex Camera.

%This code can be started before loading worms, then triggered when
%required

%% Version History
% Created by ASB at some point after January 2016
% 8-26-19 Updated to account for changes in .NET support in Matlab 2018a; loaded onto Tracking Setup #2.
% 8-27-19 Astra is amazing and I miss her. --Feli
% 8-25-21 Changed image rate from image/sec to image/min to help Ruhi's
%           needs.
% 8-26-21 Added back pre-2018a .NET support configuration for Ruhi. Code
%           now deploys the correct LabJack commands after automatically detecting
%           the matlab version number. 

%% Code
clc %Clear the MATLAB command window
clear %Clear the MATLAB variables
global StopNow
StopNow=false;

%First, generate some GUIs to collect user input
%Input Required:
%BlockNo = number of imaging blocks
prompt={'Enter Number of Imaging Blocks'};
dlgtitle='Setup Imaging Blocks';
defaultans={'9'};
answer= inputdlg(prompt,dlgtitle,1,defaultans);
BlockNo=str2num(answer{1});

%Depending on number of blocks, determine duration/imaging parameters for each block
%BlockDur = duration of each imaging block
%ImgNum = number of images to take per block
%ImgRate = Rate of image acquision, in seconds
for i=1:BlockNo
    prompt={strcat('Duration of Block #', num2str(i),' (mins)'), 'Frame Rate (frames/min)'};
    dlgtitle=strcat('Set Up Imaging Block #', num2str(i));
    if i==1
        defaultans={'1','30'};
    elseif i==2
        defaultans={'4','1'};
    elseif i==3
        defaultans={'1','30'};
    elseif i==4
        defaultans={'4','1'};
    elseif i==5
        defaultans={'1','30'};
    elseif i==6
        defaultans={'4','1'};
    elseif i==7
        defaultans={'1','30'};
    elseif i==8
        defaultans={'4','1'};
    elseif i==9
        defaultans={'1','30'};
    end
    answer= inputdlg(prompt,dlgtitle,[1, length(dlgtitle)+30],defaultans); %the +30 makes the dialog box long enough to see the title text. kinda hacky but whatever.
    BlockDur(i)=str2num(answer{1});
    ImgRate(i)=str2num(answer{2});
end

ImgNum=BlockDur.*ImgRate; %Calculate total number of images to acquire with converting image rate to images/minute
ImgRate=ImgRate/60; %number of images per second

%% Initialize LabJack - for Matlab version 2018a or later:
% Detect the version of matlab
version -release;
ver=str2num(ans(1:4));

ljasm = NET.addAssembly('LJUDDotNet'); %Make the UD .NET assembly visible in MATLAB
ljudObj = LabJack.LabJackUD.LJUD;

%Read and display the UD version.
disp(['UD Driver Version = ' num2str(ljudObj.GetDriverVersion())])

if ver>2018
    %Open the first found LabJack U3.
    [ljerror, ljhandle] = ljudObj.OpenLabJackS('LJ_dtU3', 'LJ_ctUSB','0', true, 0);
    
    %Start by using the pin_configuration_reset IOType so that all
    %pin assignments are in the factory default condition.
    Error=ljudObj.ePutS(ljhandle, 'LJ_ioPIN_CONFIGURATION_RESET', 0, 0, 0);
    ljudObj.GoOne (ljhandle);
    
    %Set digital output FIO4 to output-low.
    Error=ljudObj.AddRequestS(ljhandle, 'LJ_ioPUT_DIGITAL_BIT', 4, 0, 0, 0);
    ljudObj.GoOne (ljhandle);
else
    %Open the first found LabJack U3.
    [ljerror, ljhandle] = ljudObj.OpenLabJack(LabJack.LabJackUD.DEVICE.U3, LabJack.LabJackUD.CONNECTION.USB, '0', true, 0);
    
    %Start by using the pin_configuration_reset IOType so that all
    %pin assignments are in the factory default condition.
    Error=ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PIN_CONFIGURATION_RESET, 0, 0, 0);
    ljudObj.GoOne (ljhandle);
    
    %Set digital output FIO4 to output-low.
    Error=ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_DIGITAL_BIT, 4, 0, 0, 0);
    ljudObj.GoOne (ljhandle);
end
%% Pause code here until ready to begin image acquisision
f = figure('Position', [200 500 810 240], 'Color',[83/255 104/255 149/255]);
h = uicontrol('Position',[10 10 790 220],'String',strcat('<html>Initialize Mightex Cam Demo now<br/>',num2str(sum(ImgNum)), ' frames in queue<br/>Click to begin imaging!'),...
    'Callback','uiresume(gcbf)','BackgroundColor',[254/255 187/255 54/255],'FontSize', 30,'FontWeight','bold');

disp('Waiting to start imaging session');
uiwait(gcf);
disp('Imaging Session Initiated');
close(f);
f = figure('Position', [100 500 1060 140], 'Color',[83/255 104/255 149/255]);
h = uicontrol('Position',[10 10 1040 120],'String','Press to cancel imaging session',...
    'Callback', @PleaseStopNow,'BackgroundColor',[254/255 187/255 54/255],'FontSize', 30,'FontWeight','bold');

%Pause for 1 seconds to let user move active window back to mightex preview
disp('Pausing for 1 seconds, switch to  Mightex Camera Preview');
pause(1);
disp('Done pausing, taking pictures!');

totalN = 0;
%User Interface for Canceling Imaging Session if Necessary
for Block=1:BlockNo
    
    for N=1:ImgNum(Block)
        totalN = totalN + 1;
        if StopNow==true;
            close(f);
            clear f;
            disp('Imaging Session Canceled By User');
            break
        end
        disp(strcat('...',num2str(totalN),'/',num2str(sum(ImgNum))));
        tic
        %Set digital output FIO4 to output-high.
        if ver>2018
            Error=ljudObj.AddRequestS(ljhandle, 'LJ_ioPUT_DIGITAL_BIT', 4, 1, 0, 0);
        else
            Error=ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_DIGITAL_BIT, 4, 1, 0, 0);
        end
        ljudObj.GoOne (ljhandle);
        while toc<.00025 %250 us TTL pulse - adjust as neccessary
            ;
        end
        %Set digital output FIO4 to output-low.
        if ver>2018
            Error=ljudObj.AddRequestS(ljhandle, 'LJ_ioPUT_DIGITAL_BIT', 4, 0, 0, 0);
        else
            Error=ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_DIGITAL_BIT, 4, 0, 0, 0);
        end
        ljudObj.GoOne (ljhandle);
        if StopNow==true;
            close(f);
            clear f;
            disp('Imaging Session Canceled By User');
            break
        end
        pause(1/ImgRate(Block)) %Pause for time determined by the frame rate (value = sec/frame)
        
    end
    % Old code from when we could pause in between imaging sessions. To reintroduce functionality, need to add BlockTiming variable
    %     if Block<BlockNo
    %         disp(strcat('Pausing Between Imaging Blocks. Waiting: ', num2str(BlockTiming),' minutes'));
    %         disp('To Cancel Waiting Period, Press Ctrl-C');
    %         tic
    %
    %         while toc<(BlockTiming*60); %Pause for number of seconds determined by BlockTiming - number needs to be in seconds
    %             ;
    %         end
    %         if exist('f')
    %             close(f); clear f
    %         end
    %     end
end

disp('Imaging Session Completed');
if exist('f')
    close(f);
    clear f
end

% catch
%     showErrorMessage(Error)
% end
    function PleaseStopNow(source,callbackdata)
        disp('Canceling Imaging Session....');
        StopNow=true;
    end
end

