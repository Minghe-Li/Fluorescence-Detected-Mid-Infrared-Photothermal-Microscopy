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

% load('rampscan_300s_50deg_high_index_50kHz.mat') %Load pixel positions reference. Change the file name to match your conditions.
% load('rampscan_300s_50deg_low_index_new_50kHz.mat')

%This loop divides rawdata into pixels and averages over each pixel to
%calculate fluorescence intensity
for i = 1:Image_V_Pixel-1
    pixelgap(i) = 1400;
    for j = 1:Image_H_Pixel
        RawImage(i,j) = sum(rawdata1(1,round(low_new(i)+(j-1)*pixelgap):round(low_new(i)+(j)*pixelgap)))/length(rawdata1(1,round(low_new(i)+(j-1)*pixelgap):round(low_new(i)+(j)*pixelgap)));
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
pixgap = 1399;
pixels_IR = zeros(number_of_pixels,1400);
for i = 1:number_of_pixels
    pixels_IR(i,:) = rawdata1(low_new(j) + k*pixgap:low_new(j)+(k+1)*pixgap);
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

index_max = zeros(1,9900);
for i = 1:9900
    index_temp = find(pixels_avg(i,:) == max(pixels_avg(i,:)));
    index_max(i) = index_temp(1);
end

index_min = zeros(1,9900);
for i = 1:9900
    index_temp = find(pixels_avg(i,:) == min(pixels_avg(i,:)));
    index_min(i) = index_temp(1);
end

pixels_avg_150 = zeros(9900,150);
pixels_avg_150(:,1:500) = pixels_avg;
pixels_avg_150(:,501:1000) = pixels_avg;
pixels_avg_150(:,1001:1500) = pixels_avg;

pixels_mod_max = zeros (9900,1);
pixels_mod_min = zeros (9900,1);

for i = 1:9900
    pixels_mod_max(i) = mean(pixels_avg_150(i,index_max(i)+495:index_max(i)+505));
    pixels_mod_min(i) = mean(pixels_avg_150(i,index_min(i)+495:index_min(i)+505));
end

pixels_mod = pixels_mod_max - pixels_mod_min;

%Generate and plot image of modulation depth at each pixel

Image_modulation = reshape(pixels_mod,[Image_V_Pixel,Image_H_Pixel-1]);
Image_modulation = Image_modulation';
% Image_modulation = flip(Image_modulation,2);
figure;
imagesc(Image_modulation);
colormap(turbo); %jet - more contrast blue to red scale, can also use grayscale (colormap(gray))

