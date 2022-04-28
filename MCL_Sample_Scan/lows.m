%% 
x = (1:1:50);
y = pixels_avg(7942,:);

low_diff = zeros(1,100);

for i =1:100
    low_diff(i) = low(i+1) - low(i);
end

low_mean = 150000;

low_new = zeros(1,101);
low_new(1,1) = low(1,1);

for i = 2:101
    low_new(i) = low_new(i-1) + low_mean;
end

disp(low_mean)


high_new = zeros(1,101);
high_new(1,1) = high(1,1);

for i = 2:101
    high_new(i) = high_new(i-1) + low_mean;
end

%% 
rawdata2 = rawdata((length(rawdata)/2+1):(length(rawdata)-16));
rawdata1 = rawdata(1:((length(rawdata)/2)-16));
rawdata1 = rawdata1 - 32750;
rawdata2 = rawdata2 - 32750;

figure; plot(rawdata1);
figure; plot(rawdata2);

mean_ref = mean(rawdata2);
rawdata2 = rawdata2 - mean_ref;

% rawdata2 = rawdata2./15;
rawdata_LIA = rawdata1.*rawdata2;

figure
plot(rawdata_LIA);
%% 

pixelgap = zeros(Image_V_Pixel-1,1);

load('rampscan_300s_50deg_high_index_50kHz.mat') %Load pixel positions reference. Change the file name to match your conditions.
load('rampscan_300s_50deg_low_index_50kHz.mat')

for i = 1:Image_V_Pixel-1
    pixelgap(i) = (high(i+1) - low(i))/Image_H_Pixel;
end

number_of_pixels = (Image_V_Pixel-1)*Image_H_Pixel;
% pixels_IR = zeros (number_of_pixels,round(pixelgap));

j = 1;
k = 0;
pixgap = round(mean(pixelgap));
pixels_IR = zeros(number_of_pixels,pixgap+1);
for i = 1:number_of_pixels
    pixels_IR(i,:) = rawdata_LIA(low(j) + k*pixgap:low(j)+(k+1)*pixgap);
    k = k+1;
    if (i+1) - j*100 > 0
        j = j+1;
        k = 0;
    end
end

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
imagesc(Image_modulation);
colormap(jet); %jet - more