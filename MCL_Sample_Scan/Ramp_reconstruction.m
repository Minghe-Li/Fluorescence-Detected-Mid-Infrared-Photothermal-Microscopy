NI = zeros(200*200,1);
offset = 480;
for i = 1:40000
    NI(i,1) = mean(rawdata1(offset+1+(i-1)*10:(offset+10*i)));    
end
NI = reshape(NI,[200,200]);
NI = NI';
figure;
imagesc(NI);
colormap(gray);
colormap(flipud(gray));

FI = zeros(200,200);
for i = 1:200
    for j = 1:200
        if j<101
            FI(i,1+2*(j-1)) = NI(i,j);
        end
        if j>100
            FI(i,200-2*(j-101)) = NI(i,j);
        end
    end
end
figure;
imagesc(FI);
% colormap(gray);
colormap(flipud(gray));
%% reconstruction for 100% ramp 20s

% 100
[a,b] = size(rawdata1);
templow = [];
for i = 50:b-50
    if rawdata2(1,i)<34280 && sum(rawdata2(i-49:i))>sum(rawdata2(i:i+49))
        templow = [templow i];
    end
end
low = [];
for i = 1:length(templow)-1
    if (templow(i+1)-100)>templow(i)
        low = [low templow(i)];
    end
end
temphighe = [];
for i = 50:b-50
    if rawdata2(1,i)>38000 && sum(rawdata2(i-49:i))<sum(rawdata2(i:i+49))
        temphighe = [temphighe i];
    end
end
high = [];
for i = 1:length(temphighe)-1
    if (temphighe(i+1)-100)>temphighe(i)
        high = [high temphighe(i)];
    end
end
image = zeros(200,200);
for i = 1:200
    pixelgap = (high(i) - low(i))/200;
    for j = 1:200
        image(i,j) = sum(rawdata1(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)))/length(rawdata1(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)));
    end
end
figure;
imagesc(image);
colormap(gray);
colormap(flipud(gray));

%% reconstruction for 100% ramp

[a,b] = size(rawdata1);
templow = [];
for i = 50:b-50
    if rawdata2(1,i)<450 && sum(rawdata2(i-49:i))>sum(rawdata2(i:i+49))
        templow = [templow i];
    end
end
low = [];
for i = 1:length(templow)-1
    if (templow(i+1)-1000)>templow(i)
        low = [low templow(i)];
    end
end
temphighe = [];
for i = 50:b-50
    if rawdata2(1,i)>6300 && sum(rawdata2(i-49:i))<sum(rawdata2(i:i+49))
        temphighe = [temphighe i];
    end
end
high = [];
for i = 1:length(temphighe)-1
    if (temphighe(i+1)-1000)>temphighe(i)
        high = [high temphighe(i)];
    end
end
image = zeros(99,100);
for i = 1:99
    pixelgap = (high(i+1) - low(i))/100;
    for j = 1:100
        image(i,j) = sum(rawdata1(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)))/length(rawdata1(1,round(low(i)+(j-1)*pixelgap):round(low(i)+(j)*pixelgap)));
    end
end
figure;
imagesc(image);
colormap(gray);
colormap(flipud(gray));

        