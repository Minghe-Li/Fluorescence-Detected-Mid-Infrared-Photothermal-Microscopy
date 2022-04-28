clearvars
Frames = 32;
SignleChan = zeros(Frames,50,50);
for i = 1:Frames
    Channels = [96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127];
    x = Channels(i);
    file = load (['D:\Data\Photothermal_Shared_lab\6-25-21 Trp full spectrum 2\RawIm_chn' num2str(x) '.mat']);
    SignleChan(i,:,:) = file.RawImage2;
    SignleChan(i,:,:) = SignleChan(i,:,:);
end
fluChan = zeros(Frames,50,50);
for i = 1:Frames
    Channels = [96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127];
    x = Channels(i);
    file = load (['D:\Data\Photothermal_Shared_lab\6-25-21 Trp full spectrum 2\RawIm_fluorescence_chn' num2str(x) '.mat']);
    fluChan(i,:,:) = file.RawImage;
    fluChan(i,:,:) = fluChan(i,:,:);
end
figure, imagesc(squeeze(SignleChan(2,:,:)));
colormap(jet);
rect = getrect;
for i=1:Frames
    Means_modulation(i) = mean(mean(SignleChan(i,round(rect(2)):round(rect(2)+rect(4)),round(rect(1)):round(rect(1)+rect(3)))));
end

figure, imagesc(squeeze(fluChan(2,:,:)));
colormap(flipud(gray));
rect = getrect;
for i=1:Frames
    Means_fluor(i) = mean(mean(fluChan(i,round(rect(2)):round(rect(2)+rect(4)),round(rect(1)):round(rect(1)+rect(3)))));
end

spectrum = Means_modulation';
fluores = Means_fluor';