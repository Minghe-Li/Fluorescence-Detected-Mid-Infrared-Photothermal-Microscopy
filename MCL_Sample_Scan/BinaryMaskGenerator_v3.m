%Sylvester-type Hadamard matrix generator for QCL spectral analysis
%Written by Garth J. Simpson, 2020

clearvars;
filename = 'SilicaGel_PEG_PureSpectra.xlsx';
%Retrieve info on sheets (names & number)
[~, InputFileSheets] = xlsfinfo(filename); % Get info about input spread sheet for automatic class counting. 
SheetNum = numel(InputFileSheets); % Automatically determine the number of worksheets in input file.

for i = 1:SheetNum
    Epsilon(:,i) = xlsread(filename, InputFileSheets{i}); %Save each sheet in a different cell of the variable 'data'
end

Diff = Epsilon(:,1)/norm(Epsilon(:,1)) - Epsilon(:,2)/norm(Epsilon(:,2));
%Define an initial binary mask
Mask = zeros(2,length(Diff));
for i=1:length(Diff)
    if Diff(i)>0
        Mask(1,i)=1;
    else
        Mask(2,i)=1;
    end
end

Intensity = Mask*Epsilon;

%Goal - maximize the trace and minimize cross-elements in the Intensity

DidUpdate = 1;
Counts = 1;
while (DidUpdate) %main optimization loop
    DidUpdate = 0;
    Counts = Counts +1;
    if Counts>100 
        break
    end
    %maximize the difference in integrated intensity for the two raw
    %spectra and minimize cross-talk
    Intensity = Mask*Epsilon;
    Cost = CostFun(Mask,Epsilon);
          for j = 1:length(Diff)
            Mask(1,j) = not(Mask(1,j)); %invert each element of Mask int he optimization
            Mask(2,j) = not(Mask(2,j));
            Cost_temp = CostFun(Mask,Epsilon);
            if Cost_temp < Cost
                DidUpdate = 1; %if a change was made to Mask, update = true
            else
                Mask(1,j) = not(Mask(1,j)); %if no change made, revert to prior
                Mask(2,j) = not(Mask(2,j));
            end
         end
end
            
figure;
channel=1:1:length(Diff);
Channels = [5 6 7 8 9 10 11 15 16 17 18 21 22 23 24 25 26 27 28 29 31 32];
plot(Channels,Epsilon(:,1),Channels,Epsilon(:,2));
figure;
plot(Channels,Mask(1,:)'.*Epsilon(:,1),Channels,Mask(2,:)'.*Epsilon(:,2));
   