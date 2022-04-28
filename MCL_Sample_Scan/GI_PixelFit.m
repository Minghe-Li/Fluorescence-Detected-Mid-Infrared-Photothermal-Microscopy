[H_pixels_avg,V_pixels_avg] = size(pixels_avg);
for i = 1:H_pixels_avg
    xdata = 1:1:length(pixels_avg(0101,:));
    ydata = pixels_avg(i,:) - mean(pixels_avg(i,:));
    fun = @(x,xdata)x(1)*sin(0.1256*xdata+x(2));
    x0 = [max(ydata),1];
    if max(ydata)>80
        x = lsqcurvefit(fun,x0,xdata,ydata);
        pixels_fit(i) = x(1);
    else
        pixels_fit(i) = 0;
    end
    % figure, plot(x(1)*sin(x(3)*xdata+x(2)))
end
Image_modulation = reshape(pixels_fit,[Image_V_Pixel,Image_H_Pixel]);
Image_modulation = Image_modulation';
figure;
imagesc(Image_modulation);
colormap(jet); 

% 
% xdata = 1:1:length(pixels_avg(0101,:));
% ydata = pixels_avg(5648,:) - mean(pixels_avg(5648,:));
% fun = @(x,xdata)x(1)*sin(0.1256*xdata+x(2));
% x0 = [max(ydata),1];
% x = lsqcurvefit(fun,x0,xdata,ydata);
% figure, plot(pixels_avg(5648,:))
% figure, plot(x(1)*sin(0.1256*xdata+x(2)))
% figure,plot(ydata)