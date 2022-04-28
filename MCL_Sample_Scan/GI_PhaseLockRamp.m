load('trigger_filtered.mat')
rawdata2 = rawdata((length(rawdata)/2+1):length(rawdata));
rawdata1 = rawdata(1:((length(rawdata)/2)-16));
[pks,locs] = findpeaks(Trigger_filtered);
ClosestHighIndex = zeros(Image_V_Pixel-1,1);
ClosestLowIndex = zeros(Image_H_Pixel-1,1);
for i = 1:Image_V_Pixel-1
    [~,ClosestHighIndex(i)] = min(abs(locs-high(i+1)));
    [~,ClosestLowIndex(i)] = min(abs(locs-low(i)));
end
LineGaps = ClosestHighIndex-ClosestLowIndex;
CyclePerPixel = floor(min(LineGaps)./(Image_H_Pixel));
PhaseLockRawData = zeros(Image_V_Pixel-1,Image_H_Pixel,CyclePerPixel*ConfigParameters.GlobalSamplingRate./1000); 
DataPerPixel = CyclePerPixel*ConfigParameters.GlobalSamplingRate./1000;
DataPerCycle = ConfigParameters.GlobalSamplingRate./1000;
RawImage4 = zeros(Image_V_Pixel-1,Image_H_Pixel);
for i = 1:Image_V_Pixel-1
    for j = 1:Image_H_Pixel
        for k = 1:CyclePerPixel
%             PhaseLockRawData(i,j,:) = rawdata1((locs(ClosestLowIndex(i))+(j-1)*DataPerPixel):(locs(ClosestLowIndex(i))-1+(j*DataPerPixel)));
            PhaseLockRawData(i,j,1+(k-1)*DataPerCycle:k*DataPerCycle) = rawdata1(locs(ClosestLowIndex(i)+(j-1)*CyclePerPixel):locs(ClosestLowIndex(i)+(j-1)*CyclePerPixel)+DataPerCycle-1);
        end
        RawImage4(i,j) = max(PhaseLockRawData(i,j,:)) - min(PhaseLockRawData(i,j,:));
    end
end

for i = 1:Image_V_Pixel-1
    for j = 1:Image_H_Pixel
        PhaseLockRawData(i,j,:) = rawdata1((locs(ClosestLowIndex(i))+(j-1)*DataPerPixel):(locs(ClosestLowIndex(i))-1+(j*DataPerPixel)));
        RawImage4(i,j) = max(PhaseLockRawData(i,j,:)) - min(PhaseLockRawData(i,j,:));
    end
end



figure;
imagesc(RawImage4);
colormap(jet);
% figure, plot(squeeze(PhaseLockRawData(95,10,:)))
kk=mean(reshape(PhaseLockRawData(97,50,:),[ConfigParameters.GlobalSamplingRate./1000],CyclePerPixel),2);
figure,plot(kk)
figure,plot(squeeze(PhaseLockRawData(4,70,:)))






for i = 1:Image_V_Pixel-1
    pixelgap(i) = (high(i+1) - low(i))/Image_H_Pixel;
    for j = 1:Image_H_Pixel
        RawImage(i,j) = sum(rawdata1(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)))/length(rawdata1(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)));
    end
end
% linegap = zeros(Image_V_Pixel-1,1);
% for i =1:Image_V_Pixel-1
%     linegap(i) = high(i+1)-low(i);
% end
% avergaegap = mean(linegap);