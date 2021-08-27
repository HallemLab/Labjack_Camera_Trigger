function ValveBank_LabJackTrigger()
%This function monitors LabJack U3-LV digital inputs for TTL triggers generated
%   by a ValveBank4, and uses those triggers to initiate generation of
%   a user-defined TTL pulse sequence (via LabJack I/O) that drives image acqusition
%   via a Mightex Camera

%This code can be started before loading worms - image triggering will not
%begin until the ValveBank Trigger is detected. 

%% Version History
% 08-26-21  Modified from LabJackTrigger_v2 Created by ASB.
%   Note: If this code throws errors,
%	and you're trying to get it on a new computer, make sure the MATLAB SDK
%	add-on is loaded, that the computer has .NET libraries (you may need to
%	download Visual Studio) and that the LabJack drivers have been loaded
%	and you've run the LJControlPanel software. Even after all of that, you
%	may have to bang around trying a bunch of things before it works. Start
%	with trying to run the command ljud_LoadDriver and ljud_Constants.


%% Code
clc %Clear the MATLAB command window
clear %Clear the MATLAB variables
global StopNow
StopNow=false;

% Detect the version of matlab, make sure this is running on the correct
% version.
version -release;
ver=str2num(ans(1:4));
if ver<2018
error('This version of LabJackTrigger is too advanced for your version of Matlab. Please use Matlab 2018a or later.');
end

%First, generate some GUIs to collect user input
%Input Required:
%BlockNo = number of imaging blocks
prompt={'Enter Number of Imaging Blocks'};
dlgtitle='Setup Imaging Blocks';
defaultans={'1'};
answer= inputdlg(prompt,dlgtitle,1,defaultans);
BlockNo=str2num(answer{1});

%Depending on number of blocks, determine duration/imaging parameters for each block
%BlockDur = duration of each imaging block
%ImgNum = number of images to take per block
%ImgRate = Rate of image acquision, in seconds
for i=1:BlockNo
prompt={strcat('Duration of Block #', num2str(i),' (mins)'), 'Frame Rate (frames/min; e.g. 30 = 1 frame/2 s)'};
dlgtitle=strcat('Set Up Imaging Block #', num2str(i));
if i==1 %assuming a 1 block setup.
        defaultans={'10','30'};
end
answer= inputdlg(prompt,dlgtitle,[1, length(dlgtitle)+30],defaultans); %the +30 makes the dialog box long enough to see the title text. kinda hacky but whatever.
BlockDur(i)=str2num(answer{1});
ImgRate(i)=str2num(answer{2});
end

ImgNum=BlockDur.*ImgRate; %Calculate total number of images to acquire
ImgRate=ImgRate/60; %number of images per second

%% Initialize LabJack
ljasm = NET.addAssembly('LJUDDotNet'); %Make the UD .NET assembly visible in MATLAB
ljudObj = LabJack.LabJackUD.LJUD;

%Read and display the UD version.
disp(['UD Driver Version = ' num2str(ljudObj.GetDriverVersion())])

%Open the first found LabJack U3.
[ljerror, ljhandle] = ljudObj.OpenLabJackS('LJ_dtU3', 'LJ_ctUSB','0', true, 0);

%Start by using the pin_configuration_reset IOType so that all
%pin assignments are in the factory default condition.
%This also sets all flexible I/O to digital. 
Error=ljudObj.ePutS(ljhandle, 'LJ_ioPIN_CONFIGURATION_RESET', 0, 0, 0);
ljudObj.GoOne (ljhandle);

%Set digital output FIO4 to output-low.
Error=ljudObj.AddRequestS(ljhandle, 'LJ_ioPUT_DIGITAL_BIT', 4, 0, 0, 0);
ljudObj.GoOne (ljhandle);

%% Pause code here so users can set up camera software to recieve images
f = figure('Position', [200 500 810 240], 'Color',[83/255 104/255 149/255]);
h = uicontrol('Position',[10 10 790 220],'String',strcat('<html>Initialize Mightex Cam Demo now<br/>',num2str(sum(ImgNum)), ' frames in queue<br/>Click to start listening for ValveBank triggers!'),...
    'Callback','uiresume(gcbf)','BackgroundColor',[254/255 187/255 54/255],'FontSize', 30,'FontWeight','bold');
uiwait(gcf);
close(f);
 f = figure('Position', [100 500 1060 140], 'Color',[83/255 104/255 149/255]);
    h = uicontrol('Position',[10 10 1040 120],'String','Press to cancel imaging session',...
        'Callback', @PleaseStopNow,'BackgroundColor',[254/255 187/255 54/255],'FontSize', 30,'FontWeight','bold');
    
%% Pause until initiating trigger received by labjack
% Scanning digital I/O channels for triggers. Using command/response mode,
% since we'll be checking for triggers at a scan rate of 1,000 scans/sec or
% slower. It's also simpler than putting LabJack in stream mode. This is
% possible because the valve bank can generate "TTL" tiggers that are a
% specified duration (e.g. 2x the max scan rate of 0.001 seconds). See pg
% 35 of the ValveBank Manual.
disp('Waiting for ValveBank trigger to start imaging session');

ValveBankTrig = false;
valueDIBit = false;
while ValveBankTrig == false %currently an infinite loop, watch out.
tic
% Start monitoring for digital triggers from Labjack
Error=ljudObj.AddRequestS(ljhandle, 'LJ_ioGET_DIGITAL_BIT', 1, 0, 0, 0);

% Execute the requests
ljudObj.GoOne (ljhandle); 

% Get the results
[ljerror, valueDIBit] = ljudObj.GetResultS(ljhandle, 'LJ_ioGET_DIGITAL_BIT', 1, 0);
if valueDIBit > 0
    ValveBankTrig = true;
    disp('ValveBank TTL trigger detected. Starting image acquisition.')
end

while toc<.00025 %250 us pause before trying again.
            ;
end

end

%% Generate and send TTL triggers to camera.
for Block=1:BlockNo
   
    for N=1:ImgNum(Block)
        if StopNow==true;
            close(f);
            clear f;
            disp('Imaging Session Canceled By User');
            break
        end
        disp(strcat('...',num2str(N),'/',num2str(sum(ImgNum))));
        tic
        %Set digital output FIO4 to output-high.
        Error=ljudObj.AddRequestS(ljhandle, 'LJ_ioPUT_DIGITAL_BIT', 4, 1, 0, 0);
        ljudObj.GoOne (ljhandle);
        while toc<.00025 %250 us TTL pulse - adjust as neccessary
            ;
        end
        %Set digital output FIO4 to output-low.
        Error=ljudObj.AddRequestS(ljhandle, 'LJ_ioPUT_DIGITAL_BIT', 4, 0, 0, 0);
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
if exist('f')
         close(f); clear f
end

end

disp('Imaging Session Completed');
if exist('f')
    close(f); clear f
end

    function PleaseStopNow(source,callbackdata)
        disp('Canceling Imaging Session....');
        StopNow=true;
    end
end

