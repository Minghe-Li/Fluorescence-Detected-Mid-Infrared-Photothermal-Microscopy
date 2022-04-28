%This software is a "gated integrator" for design for alazar card. It
%basically takes a trigger from Channal A and record the signal from
%Channal B once triggered. mThe it integrate the signal from Channal B in a
%gated area return the signal strength. It's currently in alhpa testing.
clear; fclose all;
addpath('C:\DIRAC\Matlab Include');
AlazarDefs
%File path for saving the data;
FilePath = 'C:\Data\Max\20180921\PD_test_without MRA\2f_PD_no mod_cross_sin ref\'; %Always end with \
Savefile = 0;
IRChannelNumber = 5; %QCL channel number


Current_Path = pwd;
try
    cd(FilePath);
    cd(Current_Path);
catch     
    mkdir(FilePath)
end

%% Image Acq setup
Image_H_Pixel = 1; %200
Image_V_Pixel = 1; %200
Image_H_frequency = 10; % in Hz, 10
Image_V_frequency = Image_H_frequency/Image_V_Pixel; %Image_H_frequency*1/Image_V_Pixel; % in Hz
offset = 425; %425
                 
%% AlazarCard Setup
Sampling_Rate = 4; %0 for 20KSPS 1 for 1MSPS; 2 for 10MSPS; 3 for 25 MSPS; 4 for 50 MSPS; 5 for 100 MSPS;

% Channel Input Ranges.  
% 0 for +- 200mV        2 for +- 1V 
% 1 for +- 400mV        3 for +- 2V
% 4 for +- 4V           5 for +- 800mv
ChannelARange = 0; %Usually 3 for IR Photodiode
ChannelBRange = 4; 
ChannalAImpedances = 0; %0 for 50 ohms. 1 for 1 Mohms.
ChannalBImpedances = 0; %0 for 50 ohms. 1 for 1 Mohms.
External_Trigger = 0; %1
AcqParameters.Timeline = 10; %0
% Set up the trigger level in percent.
TriggerLevel = 10; % In percent of the input range of channal A. (-99 to 99)

% Switch for sampling rate input0
switch Sampling_Rate
    case 0
        ConfigParameters.SamplingRate = SAMPLE_RATE_20KSPS;
        ConfigParameters.GlobalSamplingRate = 20e3;%20e3;
    case 1
        ConfigParameters.SamplingRate = SAMPLE_RATE_1MSPS;
        ConfigParameters.GlobalSamplingRate = 1e6;
    case 2
        ConfigParameters.SamplingRate = SAMPLE_RATE_10MSPS;
        ConfigParameters.GlobalSamplingRate = 10e6;
    case 3
        ConfigParameters.SamplingRate = SAMPLE_RATE_25MSPS;
        ConfigParameters.GlobalSamplingRate = 25e6;
    case 4
        ConfigParameters.SamplingRate = SAMPLE_RATE_50MSPS;
        ConfigParameters.GlobalSamplingRate = 50e6;
    case 5
        ConfigParameters.SamplingRate = SAMPLE_RATE_100MSPS;
        ConfigParameters.GlobalSamplingRate = 1e8;
    otherwise
        disp('Error! Unsupported sampling rate! Please try number 1-5');
        return;
end

% If the card support SetBWLimit. You have to call this function if the
% card support it...
CardSupportBW = 1;

%Set up the number of pre and post trigger samples.
PreTriggerSamples = 0;
PostTriggerSamples = 10e6; %(1.0/Image_V_frequency+1.0/Image_H_frequency)*ConfigParameters.GlobalSamplingRate; %10e6;

%Advance number of trigger events settings.
%In order to make alazar card happy, you need to make sure you have enough
%samplings in one buffer. A reference point for the total number of
%samplings in a buffer is 2048*100 = 204800. 
RecordsPerBuffer = 1;%1;  %% not sure what this means
BuffersPerAcquisition = 1;

%Number of trigger events you want to caputure.!!!Auto Setting, not working
%at this stage. Please use advanced settings.
NumberofTriggerEvents = 1;

%End of user editable part.
%% 
% Add path to AlazarTech mfiles
addpath('C:\DIRAC\Matlab Include')

% Call mfile with library definitions
AlazarDefs

%Filepath
AcqParameters.FilePath = FilePath;

%Swich for input range for Channal A
switch ChannelARange
    case 0
        ConfigParameters.ChanARange = 6;
        TriggerLevelInRealWorld = 200;
        AcqParameters.RangeAinRealWorld = 200;
    case 1
        ConfigParameters.ChanARange = 7;
        TriggerLevelInRealWorld = 400;
        AcqParameters.RangeAinRealWorld = 400;
    case 2
        ConfigParameters.ChanARange = 10;
        TriggerLevelInRealWorld = 1;
        AcqParameters.RangeAinRealWorld = 1000;
    case 3
        ConfigParameters.ChanARange = 11;
        TriggerLevelInRealWorld = 2;
        AcqParameters.RangeAinRealWorld = 2000;
    case 4
        ConfigParameters.ChanARange = 12;
        TriggerLevelInRealWorld = 4;
        AcqParameters.RangeAinRealWorld = 4000;
    case 5
        ConfigParameters.ChanARange = 12;
        TriggerLevelInRealWorld = 800;
        AcqParameters.RangeAinRealWorld = 800;
    otherwise
        disp('Error! Unsupported input range! Please try number 0-4');
        return;
end

%Swich for input range for Channal B
switch ChannelBRange
    case 0
        ConfigParameters.ChanBRange = 6;
        AcqParameters.RangeBinRealWorld = 200;
    case 1
        ConfigParameters.ChanBRange = 7;
        AcqParameters.RangeBinRealWorld = 400;
    case 2
        ConfigParameters.ChanBRange = 10;
        AcqParameters.RangeBinRealWorld = 1000;
    case 3
        ConfigParameters.ChanBRange = 11;
        AcqParameters.RangeBinRealWorld = 2000;
    case 4
        ConfigParameters.ChanBRange = 12;
        AcqParameters.RangeBinRealWorld = 4000;
    otherwise
        disp('Error! Unsupported input range! Please try number 0-4');
        return;
end

%Set up the impedances.
ConfigParameters.ChanAImp = -ChannalAImpedances + 2;
ConfigParameters.ChanBImp = -ChannalBImpedances + 2;

%Set up trigger level.
ConfigParameters.TriggerLevel = floor(TriggerLevel/100*128+128);
if TriggerLevelInRealWorld > 25
    fprintf('Current trigger level is %d mV\n', TriggerLevelInRealWorld*TriggerLevel/100);
else
    fprintf('Current trigger level is %d V\n', TriggerLevelInRealWorld*TriggerLevel/100);
end

%Set External Trigger.
ConfigParameters.External_Trigger = External_Trigger;

%See if the card support set BW limit function.
ConfigParameters.CardSupportBW = CardSupportBW;

%Set up the number of samples to capture per trigger.
AcqParameters.PreTriggerSamples = PreTriggerSamples;
AcqParameters.PostTriggerSamples = PostTriggerSamples;

%Number of total trigger events.
AcqParameters.NumberofHundredsTriggersEventtoCapture = NumberofTriggerEvents;

%Big IF for auto/advanced record settings
AcqParameters.RecordsPerBuffer = RecordsPerBuffer;
AcqParameters.BuffersPerAcquisition = BuffersPerAcquisition;

% Load driver library
if ~alazarLoadLibrary()
    fprintf('Error: ATSApi library not loaded\n');
    return
end

% TODO: Select a board
systemId = int32(1);
boardId = int32(1);

% Get a handle to the board
boardHandle = AlazarGetBoardBySystemID(systemId, boardId);
setdatatype(boardHandle, 'voidPtr', 1, 1);
if boardHandle.Value == 0
    fprintf('Error: Unable to open board system ID %u board ID %u\n', systemId, boardId);
    return
end

% Configure the board's sample rate, input, and trigger settings
if ~configureBoard(boardHandle,ConfigParameters)
    fprintf('Error: Board configuration failed\n');
    return
end


%%

try
    [result,rawdata]=acquireData(boardHandle,AcqParameters);
catch
        fprintf('Error: Acquisition failed\n');            
        return
end

if ~result
        fprintf('Error: Acquisition failed\n');
        return
end
rawdata2 = rawdata((length(rawdata)/2+1):length(rawdata));
rawdata1 = rawdata(1:length(rawdata)/2);
% rawdata1 = rawdata;
samplesperline = (1.0/Image_H_frequency)*ConfigParameters.GlobalSamplingRate;
data = rawdata1(offset+1:offset+(1.0/Image_V_frequency)*ConfigParameters.GlobalSamplingRate);
data = reshape(data,[samplesperline,Image_V_Pixel]);

% data2 = rawdata2(offset+1:offset+(1.0/Image_V_frequency)*ConfigParameters.GlobalSamplingRate);
% data2 = reshape(data2,[samplesperline,Image_V_Pixel]);

index = ones(Image_H_Pixel+1,1);
for i = 1:Image_H_Pixel
    x = acos(1 - 2*i/Image_H_Pixel);
    index(i+1) = fix(x/pi*(samplesperline/2));
end 

RawImage = ones(Image_V_Pixel,Image_H_Pixel);
% RawImage2 = ones(Image_V_Pixel,Image_H_Pixel);
for i = 1:Image_V_Pixel
    line_data = (data(1:samplesperline/2,i));%+flip(i,data(samplesperline/2+1:end)))/2;
    for j = 1:Image_H_Pixel                      
        RawImage(i,j) = mean(line_data(index(j):index(j+1)));
    end
end

% for i = 1:Image_V_Pixel
%     line_data = (data2(1:samplesperline/2,i));%+flip(i,data(samplesperline/2+1:end)))/2;
%     for j = 1:Image_H_Pixel                      
%         RawImage2(i,j) = mean(line_data(index(j):index(j+1)));
%     end
% end
% 
% figure;
% imagesc(RawImage);
colormap(gray);
figure;
plot(rawdata1);
figure;
plot(rawdata2);
 
% figure;
% imagesc(RawImage2);
% colormap(gray);


if Savefile
    save(['D:\Data\Photothermal_LT\IR Channels at optimal Voltage 2\Raw_chan' num2str(IRChannelNumber) '_10us.mat'] , 'rawdata1');
%     FileNameA = strcat(FilePath,datestr(now,'HH-MM-SS'),'_ChanA.txt');
%     dlmwrite(FileNameA, RawImage);
%     FileNameB = strcat(FilePath,datestr(now,'HH-MM-SS'),'_ChanB.txt');
%     dlmwrite(FileNameB, RawImage2);
end

