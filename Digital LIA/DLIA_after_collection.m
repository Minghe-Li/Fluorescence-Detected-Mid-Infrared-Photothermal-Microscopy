load('trigger_filtered.mat')
y = Trigger_filtered;
[a, b] = size(rawdata1);
Cost = zeros(1,50);
for Phase_Shift = 1:50 % For 1kHz modulation and 50kHz sampling rate, the phase is ranging from 1-50
    bandpass_fluorescence = rawdata1;
    bandpass_fluorescence = bandpass_fluorescence-2^15;
    LIA_signal = bandpass_fluorescence(1:b-50).*y(1+Phase_Shift:b-50+Phase_Shift);
    MCLIA = movmean(LIA_signal,500); % 500 data points = 10ms time constant 
    Cost(Phase_Shift) = sum(MCLIA);
end
MatchingPhase = find(Cost == max(Cost));
bandpass_fluorescence = rawdata1;
bandpass_fluorescence = bandpass_fluorescence-2^15;
Product = bandpass_fluorescence(1:b-50).*y(1+MatchingPhase:b-50+MatchingPhase);
LIA = movmean(Product,500);
% figure, plot(LIA)
%% Image construction
rawdata3 = abs(LIA);
RawImage3 = zeros(Image_V_Pixel-1,Image_H_Pixel); %preallocate an array for the image
pixelgap = zeros(Image_V_Pixel-1,1);
for i = 1:Image_V_Pixel-1
    pixelgap(i) = (high(i+1) - low(i))/Image_H_Pixel;
    for j = 1:Image_H_Pixel
        RawImage3(i,j) = sum(rawdata3(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)))/length(rawdata3(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)));
    end
end
%Plot the LIA image
figure;
imagesc(RawImage3);
colormap(jet); 