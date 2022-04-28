%This software is designed to acquire signal in sample-scanning mode using
%the Nano-Bio piezo-stage. It supports similtaneous data acquisition using
%two channels (A and B). For fluorescence microscopy in most cases it
%should be enough to simply collect PMT output in channel A.

% For this code to work properly, the piezo stage should be triggered by a couple of
% function generators, when both slow and fast axes are driven by ramp
% functions starting at 270 degree phase. use AcqToDisk if sin function is
% prefered to drive the fast axis.

% Written by Aleksandr Razumtcev based on the old AcqToDisk sample scan code by Simpson Lab for Nonlinear
% Optics. Modified on 7/15/2021

clear; fclose all;
addpath('C:\DIRAC\Matlab Include');
AlazarDefs

%File path for saving the data. Change Savefile to 1 to automatically save
%rawdata and reconstructed images.
FilePath = 'D:\Data\Photothermal_Shared_lab\7-14-21 Gated integration test\'; %Always end with \
Savefile = 0; %Change to 1 to automatically save all images and rawdata

%% Specify image acquisition parameters

%Number of pixels on each axis. 200x200 by default. Might change to higher
%or lower resolution, but adjust the driving frequencies accordingly.

Image_H_Pixel = 200;
Image_V_Pixel = 200; 

Image_H_frequency = 10; %Frequency of the fast-axis trigger in Hz. 20 by default for 10 seconds acquisition  
Image_V_frequency = Image_H_frequency/Image_V_Pixel; %Calculates automatically in Hz. Make sure that it equals to slow-axis trigger frequency.
offset = 65; %Might drift. Usually  for 4V/5V FOV and 65 for 8V/10V FOV. 

%% AlazarCard Setup
Sampling_Rate = 0; %0 for 20KSPS 1 for 1MSPS; 2 for 10MSPS; 3 for 25 MSPS; 4 for 50 MSPS; 5 for 100 MSPS;
%Decrease if "buffer overflow" error occurs. 0 is enough for normal
%fluorescence image.

% Channel Input Ranges.  
% 0 for +- 200mV        2 for +- 1V - DOESNT WORK WITH THIS CARD
% 1 for +- 400mV        3 for +- 2V
% 4 for +- 4V           5 for +- 800mv
% 6 for +- 8V at 1MOhms 7 for +- 16V at 1MOhms
ChannelARange = 4; %Increase to avoid saturation or decrease to improve sensitivity. 
ChannelBRange = 4; 
ChannelAImpedances = 0; %0 for 50 ohms. 1 for 1 Mohms.
ChannelBImpedances = 0; %0 for 50 ohms. 1 for 1 Mohms.
External_Trigger = 1; %If 1, acquision will only be successful if the stage finishes its movement. Use 0 when want to disable the stage.
AcqParameters.Timeline = 0; %In seconds. Should be larger than image acquisition time. 0 is default and corresponds to 30 s.
TriggerLevel = 20; % In percent of the input range of channel A.

% Switch for sampling rate. Only change if you know what you are doing.
switch Sampling_Rate
    case 0
        ConfigParameters.SamplingRate = SAMPLE_RATE_20KSPS;
        ConfigParameters.GlobalSamplingRate = 20e3;
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

% If the card support SetBWLimit, you have to call this function.
CardSupportBW = 1;

%The number of pre and post trigger samples. The latter should be
%calculated automatically and determines when the acquisition will stop.
%You may change it to a certain value if External_Trigger=0.
PreTriggerSamples = 0; %Usually 0.
PostTriggerSamples = (1.0/Image_V_frequency+1.0/Image_H_frequency)*ConfigParameters.GlobalSamplingRate; %10e6;

%Advanced number of trigger events settings.
%In order to make the alazar card happy, you need to make sure you have enough
%samplings in one buffer. A reference point for the total number of
%samplings in a buffer is 2048*100 = 204800. 
RecordsPerBuffer = 1; % not sure what this means
BuffersPerAcquisition = 1;

%Number of trigger events you want to capture.Auto Settings do not work
%with this stage.
NumberofTriggerEvents = 1;

%End of user editable part.

%% Do not edit this section, skip straight to Image reconstruction section

% Add path to AlazarTech mfiles
addpath('C:\DIRAC\Matlab Include')

% Call mfile with library definitions
AlazarDefs

%Filepath
AcqParameters.FilePath = FilePath;

%Swich for input range for Channel A
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
    case 6
        ConfigParameters.ChanARange = 14;
        TriggerLevelInRealWorld = 8;
        AcqParameters.RangeAinRealWorld = 8000;
    case 7
        ConfigParameters.ChanARange = 18;
        TriggerLevelInRealWorld = 16;
        AcqParameters.RangeAinRealWorld = 16000;
    otherwise
        disp('Error! Unsupported input range! Please try number 0-4');
        return;
end

%Swich for input range for Channel B
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
ConfigParameters.ChanAImp = -ChannelAImpedances + 2;
ConfigParameters.ChanBImp = -ChannelBImpedances + 2;

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


%% Image reconstruction section

%Here, the acqusition starts and it will finish once the required number of
%datapoints is collected.

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


%Rawdata is the whole rawdata collected from 2 channels, here it is divided
%into rawdata1 (channel A/fluorescence intensity) and rawdata2 (channel B/QCL reference

rawdata2 = rawdata((length(rawdata)/2+1):length(rawdata));
rawdata1 = rawdata(1:length(rawdata)/2);

samplesperline = (1.0/Image_H_frequency)*ConfigParameters.GlobalSamplingRate;
number_of_pixels = Image_V_Pixel*Image_H_Pixel;

data = rawdata1(offset+1:offset+(1.0/Image_V_frequency)*ConfigParameters.GlobalSamplingRate);
% data = reshape(data,[samplesperline,Image_V_Pixel]);

% data2 = rawdata2(offset+1:offset+(1.0/Image_V_frequency)*ConfigParameters.GlobalSamplingRate);
% data2 = reshape(data2,[samplesperline,Image_V_Pixel]);

lines = zeros(Image_H_Pixel,samplesperline);

for i = 1:Image_H_Pixel
    lines(i,:) = data(1+(i-1)*samplesperline:i*samplesperline);
end

newlines_start = ceil(samplesperline*0.2);
newlines_end = ceil(samplesperline*0.8);
samplesperline_corrected = samplesperline*0.6;

newlines = zeros(Image_H_Pixel,ceil(samplesperline_corrected));

for i = 1:Image_H_Pixel
    newlines(i,:) = lines(i,newlines_start:(newlines_end-1));
end

newlines = newlines';
data_corrected = reshape(newlines,[1,numel(newlines)]);

samplesperpixel = floor(samplesperline_corrected/Image_H_Pixel);

%
% for j = 2:2:Image_H_Pixel
%     lines(j,:) = flip(lines(j,:));
% end

% lines2 = zeros(Image_H_Pixel,samplesperline);
% 
% for i = 1:Image_H_Pixel
%     lines2(i,:) = data2(1+(i-1)*samplesperline:i*samplesperline);
% end
% 
% for j = 2:2:Image_H_Pixel
%     lines2(j,:) = flip(lines2(j,:));
% end
% 
% lines2 = lines2';
% data_corrected2 = reshape(lines2,[1,numel(lines2)]); %substitute with lines_corrected if needed


%Create and populate an array in which each row contains only datapoints
%attributed to a single pixel

pixels = zeros(number_of_pixels,samplesperpixel);

for i = 1:number_of_pixels;
    pixels(i,:) = data_corrected(1+(i-1)*samplesperpixel:i*samplesperpixel);
end

pixels_avg = mean(pixels,2);

RawImage = reshape(pixels_avg,[Image_H_Pixel,Image_V_Pixel]);
RawImage = RawImage';
figure;
imagesc(RawImage);
colormap(flipud(gray)); 

figure;
plot(rawdata1);

% pixels2 = zeros(number_of_pixels,samplesperpixel);
% 
% for i = 1:number_of_pixels;
%     pixels2(i,:) = data_corrected2(1+(i-1)*samplesperpixel:i*samplesperpixel);
% end
% 
% pixels_avg2 = mean(pixels2,2);
% 
% RawImage2 = reshape(pixels_avg2,[Image_H_Pixel,Image_V_Pixel]);
% RawImage2 = RawImage2';
% figure;
% imagesc(RawImage2);
% colormap(flipud(gray)); 