clearvars

SingleChan = zeros(25,1,10000000);
for i = 1:25
    Channels = [2 3 4 5 6 7 8 9 10 11 15 16 17 18 21 22 23 24 25 26 27 28 29 31 32];
    x = Channels(i);
    file = load (['D:\Data\Photothermal_LT\IR Channels at optimal Voltage\Raw_chan' num2str(x) '_10us.mat']);
    SingleChan(i,:,:) = file.rawdata1;
    %SignleChan(i,:,:) = SignleChan(i,:,:)-328;
end

Average = zeros(1,25);

for m = 1:25
Average(1,m) = max(SingleChan(m,:,:)-32800);
end
figure, plot(Channels,Average)

spectrum = Average';

% Chan17 = SingleChan(14,:,:);
% Chan17 = squeeze(Chan17);
% figure, plot(Chan17);
