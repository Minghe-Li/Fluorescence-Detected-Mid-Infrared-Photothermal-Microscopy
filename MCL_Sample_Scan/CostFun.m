function [out] = CostFun(mask,epsilon)
%calculation of the cost for optimization of the binary mask

%normalize pure component spectra in epsilon
for i = 1:length(epsilon(1,:));
    epsilon_norm(:,i)=epsilon(:,i)/norm(epsilon(:,i));
end
intensity = mask*epsilon_norm;

%intensity = mask*epsilon;
%cost1 selects to minimize cross-talk reflected in the off-diagonal terms
%of the intensity matrix
cost1 = (sum(intensity,'all')-trace(intensity) / sum(intensity,'all'));
%cost2 selects to maintain constant integrated intensity betwen the two
%channels. 
%cost2 = abs(intensity(1,1)-intensity(2,2));
cost2 = 1;
out = cost1+cost2;

end
