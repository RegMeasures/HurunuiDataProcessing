function [Constituent,Amplitude,Phase] = ReadCns(CnsFile)
%READCNS Read tidal constituent data from *.cns file
%   [Constituent,Amplitude,Phase] = ReadCns('FileName.cns') reads tidal 
%   constituent data from a *.cns file.
% 
%   Notes: 
%   For the moment ReadCns only reads the first site in the *.cns file.
%
%   See also AstronomicTide
%   
%   Richard Measures 2016

FID = fopen(CnsFile);
Imported = textscan(FID,'%s %*f %f %f %*f %*f ','HeaderLines',1);
fclose(FID);

if isnan(Imported{1,3}(end))
    Imported = cellfun(@(v) v(1:end-1), Imported, 'UniformOutput', false);
end

Constituent = Imported{1,1};
Amplitude = Imported{1,2};
Phase = Imported{1,3};

end

