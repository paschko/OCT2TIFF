function exportAllToTiff(parentDir)

% exportAllToTif
% This script looks for files ending in '.oct' in ALL subdirectories
% of the passed directory. For each found 2D OCT file it creates a folder
% (in the same location as the found file) with the name of the file and
% exports every single frame of the 2D file as TIFF to the folder. It uses
% the refractive index information of the OCT file and applies the
% correction for refractive index and anisotropy before saving which
% results in a physically true aspect ratio of the exported images.

% Author: pascal.ackermann@yale.edu
% Date: 7/9/18


allFiles = dirrec(parentDir);
filesN = length(allFiles);
for i = 1:filesN
    if endsWith(allFiles{i}, '.oct')
        filePath = allFiles{i};
        filePath = fullfile(filePath);
        [folderPath,filename,~] = fileparts(filePath);
        
        tifFolderPath = fullfile(folderPath, filename);
        if ~exist(tifFolderPath, 'dir')
            disp(filePath);
            mkdir(tifFolderPath);
            % open image
            handle = OCTFileOpen(filePath);
            OCTPATools.saveImages(handle, tifFolderPath);
            
        end
    end
end

end