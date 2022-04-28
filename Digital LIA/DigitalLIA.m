%% For rawdata without split
clear; fclose all;
AlazarDefs
load('C:\Users\Minghe\Desktop\8-31-21 System after repair tests\Silica Gel\split rawdata\1kHz_trigger.mat');
% Specify image acquisition parameters

%Number of pixels on each axis. 100x100 by default to increase spectral
%accuracy. Use 200x200 for faster high-resolution imaging if SNR permits
Image_H_Pixel = 100;
Image_V_Pixel = 100; 

Image_H_frequency = 1/3; %Frequency of the fast-axis trigger in Hz. 1/3 by default (3 seconds per fast line, 300 seconds total), change based on pixel dwell time and total imaging time.  
Image_V_frequency = Image_H_frequency/Image_V_Pixel; %Calculates automatically in Hz. Make sure that it equals to slow-axis trigger frequency.
offset = 480; %Artifact from the older versions. Not used, but keep this line to avoid errors.

% Specify QCL modulation settings

MidIR_freq = 1; %QCL modulation frequency in kHz (the slowest one when using 2 function generators)
MidIR_period = 1/(MidIR_freq*1000); %In seconds
                 
% AlazarCard Acquision Parameters

Sampling_Rate = 1; %0 for 20KSPS 1 for 50KSPS; 2 for 1MSPS; 3 for 10 MSPS; 4 for 25 MSPS; 5 for 50 MSPS;
%Decrease if "buffer overflow" error occurs


% Channel Input Ranges.  
% 0 for +- 200mV        2 for +- 1V - DOESNT WORK WITH THIS CARD
% 1 for +- 400mV        3 for +- 2V
% 4 for +- 4V           5 for +- 800mv
ChannelARange = 4; %Usually 4 (largest input range)
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

%load image construction data
load('rampscan_300s_50deg_high_index_50kHz.mat') %Load pixel positions reference. Change the file name to match your conditions.
load('rampscan_300s_50deg_low_index_50kHz.mat')

% Split data
rawdata2 = rawdata((length(rawdata)/2+1):length(rawdata));
rawdata1 = rawdata(1:length(rawdata)/2);

%End of user editable part.
%% Load split rawdata
ST1 = load('C:\Users\Minghe\Desktop\8-31-21 System after repair tests\Silica Gel\split rawdata\1kHz_trigger.mat');
ST2 = load('C:\Users\Minghe\Desktop\8-31-21 System after repair tests\Silica Gel\split rawdata\Bandpass_raw.mat');
ST3 = load('C:\Users\Minghe\Desktop\8-31-21 System after repair tests\Silica Gel\split rawdata\LIA.mat');
ST4 = load('C:\Users\Minghe\Desktop\8-31-21 System after repair tests\Silica Gel\split rawdata\fluorescence.mat');
Fluorescence = ST4.rawdata1;
LockIn = ST3.rawdata2;
Trigger = ST1.rawdata2;
Bandpass_S = ST2.rawdata1;
%% Bandpass filter(works for Matlab 2021a or later)
fs = ConfigParameters.GlobalSamplingRate; % smaple frequency in Hz
bandpass_fluorescence = bandpass(Fluorescence,[800 1250],fs);
[a, b] = size(Fluorescence);

% Generate Reference
x=1:1:b+100;
y= sin(2*pi.*x./50);

% Cost function to find phase matching
Cost = zeros(1,50);
for Phase_Shift = 1:50 % For 1kHz modulation and 50kHz sampling rate, the phase is ranging from 1-50
    LIA_signal = bandpass_fluorescence.*y(1+Phase_Shift:b+Phase_Shift);
    CLIA_signal = LIA_signal(1:b-20); % Get rid of tail
    MCLIA = movmean(CLIA_signal,500); % 500 data points = 10ms time constant 
    Cost(Phase_Shift) = sum(MCLIA);
end
MatchingPhase = find(Cost == max(Cost));
% figure, plot(Cost)
MatchingPhase = 44;
bandpass_fluorescence = bandpass_fluorescence-2^15;
Product = bandpass_fluorescence.*y(1+MatchingPhase:b+MatchingPhase);
LIA = movmean(Product,500);
figure, plot(LIA)

%% Image construction
rawdata2 = LIA;
for i = 1:length(rawdata2)
        if rawdata2(i)<0
            rawdata2(i) = 0;
        end
end
RawImage2 = zeros(Image_V_Pixel-1,Image_H_Pixel); %preallocate an array for the image
pixelgap = zeros(Image_V_Pixel-1,1);
for i = 1:Image_V_Pixel-1
    pixelgap(i) = (high(i+1) - low(i))/Image_H_Pixel;
    for j = 1:Image_H_Pixel
        RawImage2(i,j) = sum(rawdata2(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)))/length(rawdata2(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)));
    end
end
%Plot the LIA image
figure;
imagesc(RawImage2);
colormap(jet); 