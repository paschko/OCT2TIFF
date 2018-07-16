function [ handle ] = OCTFileOpen( filename )
% OCTFILEOPEN  Open .oct file.
%   handle = OCTFILEOPEN( filename ) Open .oct file located at filename
%
%   The data files inside the .oct file are extracted into the temporary
%   directory and removed when OCTFileClose is called
%
%   See also OCTFILECLOSE
%

handle.filename = filename;
%handle.path = [pwd, '\OCTData\'];
% for windows(?): 
%handle.path = [tempdir], 'OCTData\'];
% for Mac:
handle.path = [tempdir, 'OCTData/'];
% packermann: overwriting the unzip dir, because low disk space and huge
% data...
%handle.path = ['/Volumes/Bunker/Temp/MATLAB/oct_temp/OCTData_',num2str(randi(10000)), '/'];



if exist(handle.path,'file')
   rmdir(handle.path, 's')
end
if ~exist(handle.path,'file')
   mkdir(handle.path, 's')
end
unzip(filename, handle.path);
handle.xml = xmlread([handle.path, 'Header.xml']);
head_oct = xml2struct([handle.path, 'Header.xml']);
handle.head = head_oct.Ocity;

end

