% This software is designed for F-PTIR imaging. The code averages the
% collected fluorescence intensity over mid-IR modulation periods and maps
% the modulation depth on each pixel to reconstruct the modulation image.

% The code is designed to work with 2 input channels (fluorescence
% intensity collected from a PMT as chanA and mid-IR laser reference
% collected as chanB) in sample scan mode (see lab notebook for details).

% This code is designed for a 100% ramp function as a driver for fast axis.

% Written by Minghe Li  and Aleksandr Razumtcev based on the old AcqToDisk sample scan code by Simpson Lab for Nonlinear
% Optics. Modified on 7/20/2021

clear; fclose all;
addpath('C:\DIRAC\Matlab Include');
AlazarDefs

%File path for saving the data. Change Savefile to 1 to automatically save
%rawdata and reconstructed images.
FilePath = 'D:\Data\Photothermal_Shared_lab\7-14-21 Gated integration test\'; %Always end with \
Savefile = 0; %Change to 1 to automatically save all images and rawdata

IRChannelNumber = 97; %Indicate the used QCL channel for the file name. (Only needed when Savefile = 1)


%% Specify image acquisition parameters

%Number of pixels on each axis. 100x100 by default to increase spectral
%accuracy. Use 200x200 for faster high-resolution imaging if SNR permits
Image_H_Pixel = 100;
Image_V_Pixel = 100; 

Image_H_frequency = 1/3; %Frequency of the fast-axis trigger in Hz. 1/3 by default (3 seconds per fast line, 300 seconds total), change based on pixel dwell time and total imaging time.  
Image_V_frequency = Image_H_frequency/Image_V_Pixel; %Calculates automatically in Hz. Make sure that it equals to slow-axis trigger frequency.
offset = 480; %Artifact from the older versions. Not used, but keep this line to avoid errors.

%% Specify QCL modulation settings

MidIR_freq = 1; %QCL modulation frequency in kHz (the slowest one when using 2 function generators)
MidIR_period = 1/(MidIR_freq*1000); %In seconds
                 
%% AlazarCard Acquision Parameters

Sampling_Rate = 1; %0 for 20KSPS 1 for 50KSPS; 2 for 1MSPS; 3 for 10 MSPS; 4 for 25 MSPS; 5 for 50 MSPS;
%Decrease if "buffer overflow" error occurs

% 0 for +- 200mV   3 fo
% Channel Input Rangesr +- 2V
% 4 for +- 4V           2 for +- 1V - DOESNT WORK WITH THIS CARD
% 1 for +- 400mV             5 for +- 800mv
ChannelARange = 0; %Usually 4 (largest input range)
ChannelBRange = 4; %Almost always 4 for Lock-In detection.
ChannalAImpedances = 0; %0 for 50 ohms. 1 for 1 Mohms. Always 0.
ChannalBImpedances = 0; %0 for 50 ohms. 1 for 1 Mohms. Always 0.
External_Trigger = 1; %
AcqParameters.Timeline = 360; %In seconds. Should be larger than image acquisition time. Use 360 for 300s acquisition.
TriggerLevel = 20; % In percent of the input range of channel A.

% Switch for sampling rate. Only change if you know what you are doing.
switch Sampling_Rate
    case 0
        ConfigParameters.SamplingRate = SAMPLE_RATE_20KSPS;
        ConfigParameters.GlobalSamplingRate = 20e3;
    case 1
        ConfigParameters.SamplingRate = SAMPLE_RATE_50KSPS;
        ConfigParameters.GlobalSamplingRate = 50e3;
    case 2
        ConfigParameters.SamplingRate = SAMPLE_RATE_1MSPS;
        ConfigParameters.GlobalSamplingRate = 1e6;
    case 3
        ConfigParameters.SamplingRate = SAMPLE_RATE_10MSPS;
        ConfigParameters.GlobalSamplingRate = 10e6;
    case 4
        ConfigParameters.SamplingRate = SAMPLE_RATE_25MSPS;
        ConfigParameters.GlobalSamplingRate = 25e6;
    case 5
        ConfigParameters.SamplingRate = SAMPLE_RATE_50MSPS;
        ConfigParameters.GlobalSamplingRate = 50e6;
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

%Number of trigger events you want to capture. Auto Settings do not work
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

%Set up impedances.
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

%See if the card supports the "set BW limit" function.
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
%into rawdata1 (channel A/fluorescence intensity) and rawdata2 (channel B/QCL reference)

rawdata2 = rawdata((length(rawdata)/2+1):length(rawdata));
rawdata1 = rawdata(1:((length(rawdata)/2)-16));

%Next, the code recontructs a fluorescence image. It is done based on a
%reference from the piezo stage (to know precisely when the stage is
%scanning each line). Because this alazar cards only has 2 input channels,
%we cannot collect fluorescence intensity, QCL reference for modulation and
%stage reference at the same time. Instead, we have precollected the stage
%reference and found the pixels positions for the most commonly used
%imaging conditions. The code loads 2 files for the set of imaging
%conditions and uses it to recontruct the image. if you need to use a new
%set of imaging conditions, run a test acquisition with stage reference in
%channel B and calculate the "high" and "low" files using the
%"Ramp_reconstruction" function

RawImage = zeros(Image_V_Pixel-1,Image_H_Pixel); %preallocate an array for the image
pixelgap = zeros(Image_V_Pixel-1,1);

load('rampscan_300s_50deg_high_index_50kHz.mat') %Load pixel positions reference. Change the file name to match your conditions.
load('rampscan_300s_50deg_low_index_50kHz.mat')

%This loop divides rawdata into pixels and averages over each pixel to
%calculate fluorescence intensity
for i = 1:Image_V_Pixel-1
    pixelgap(i) = (high(i+1) - low(i))/Image_H_Pixel;
    for j = 1:Image_H_Pixel
        RawImage(i,j) = sum(rawdata1(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)))/length(rawdata1(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)));
    end
end

%Plot the fluorescence image
figure;
imagesc(RawImage);
colormap(flipud(gray)); %Change the colormap to any other if you like 

if Savefile
    saveas(gcf,[FilePath num2str(IRChannelNumber) '.tif']);
end

% figure; %Uncomment if you want to plot rawdata for channel 1
% plot(rawdata1);
%% 

number_of_pixels = (Image_V_Pixel-1)*Image_H_Pixel;
% pixels_IR = zeros (number_of_pixels,round(pixelgap));

j = 1;
k = 0;
pixgap = round(mean(pixelgap));
pixels_IR = zeros(number_of_pixels,pixgap+1);
for i = 1:number_of_pixels
    pixels_IR(i,:) = rawdata1(low(j) + k*pixgap:low(j)+(k+1)*pixgap);
    k = k+1;
    if (i+1) - j*100 > 0
        j = j+1;
        k = 0;
    end
end
%% 

samplesperIRperiod = MidIR_period*ConfigParameters.GlobalSamplingRate;
pixels_avg = zeros(number_of_pixels,samplesperIRperiod);

for i=1:number_of_pixels
   for j = 1:samplesperIRperiod
       pixel_temp = 0;
       for k = 1:(pixgap/samplesperIRperiod - 1)
           pixel_temp2 = pixels_IR(i,j+(k-1)*samplesperIRperiod);
           pixel_temp = pixel_temp + pixel_temp2;
       end
       pixels_avg(i,j) = pixel_temp/(pixgap/samplesperIRperiod);
   end
end

%Calculate modulation depth simply by taking the difference between the
%initial fluorescence intensity and intensity during an IR firing event

pixels_mod = max(pixels_avg,[],2) - min(pixels_avg,[],2);

%Generate and plot image of modulation depth at each pixel

Image_modulation = reshape(pixels_mod,[Image_V_Pixel,Image_H_Pixel-1]);
Image_modulation = Image_modulation';
% Image_modulation = flip(Image_modulation,2);
figure;
imagesc(Image_modulation(1:99,1:99));
colormap(jet); %jet - more contrast blue to red scale, can also use grayscale (colormap(gray))



figure;
plot(rawdata2);
%% 

%calculate LIA intensity

rawdata2 = rawdata2 - 32700;
for i = 1:length(rawdata2)
        rawdata2(i) = abs(rawdata2(i));
end
RawImage2 = zeros(Image_V_Pixel-1,Image_H_Pixel); %preallocate an array for the image


for i = 1:Image_V_Pixel-1
    pixelgap(i) = (high(i+1) - low(i))/Image_H_Pixel;
    for j = 1:Image_H_Pixel
        RawImage2(i,j) = sum(rawdata2(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)))/length(rawdata1(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)));
    end
end

%Plot the LIA image
figure;
imagesc(RawImage2);
colormap(jet); 
%% 

if Savefile
    save([FilePath num2str(IRChannelNumber) '_conditions.mat'] , 'rawdata');
    save([FilePath num2str(IRChannelNumber) '.mat'] , 'Image_modulation');
    save([FilePath num2str(IRChannelNumber) '.mat'] , 'RawImage');
end
 

