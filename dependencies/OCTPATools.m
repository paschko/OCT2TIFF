classdef OCTPATools < handle
    %OCTPATools Tools and shortcuts for OCT Toolbox by Pascal Ackermann
    
    methods(Static)
        function image = getImage(filename)
            obj = OCTFileReader(filename);
            df = obj.getDataFiles();
            im = df{1,4};
            image = im.getImage();
        end
        
        % Correction functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function resImage = correctForRefractiveIndex(handle, img) % actually it also corrects for the spacing differences
            % CORRECTFORREFRACTIVEINDEX  Corrects OCT image(s) for refractive index by parsing it from the header file.
            %   resImages = CORRECTFORREFRACTIVEINDEX(handle) Applies the correction for all images and returns them as a cell.
            %   resImage = CORRECTFORREFRACTIVEINDEX(handle, img) Applies the correction to a single img but needs the handle to access the header.
            %
            %   See also GETCORRECTEDOCTIMAGES, DBTOPIXELINTENSITY.
            
            props = OCTFileGetProperties(handle);
            pixelSpacingZ = str2double(props.Image.PixelSpacing.SpacingZ.Text);
            pixelSpacingX = str2double(props.Image.PixelSpacing.SpacingX.Text);
            refractiveIndex = str2double(props.Acquisition.RefractiveIndex.Text);
            pixelAspectRatio = pixelSpacingX/pixelSpacingZ;
            oldHeight = str2double(props.Image.SizePixel.SizeZ.Text);
            oldWidth = str2double(props.Image.SizePixel.SizeX.Text);
            if(pixelAspectRatio >= 1)
                newWidth = int32(oldWidth * pixelAspectRatio*refractiveIndex);
                newHeight = oldHeight;
            else
                pixelAspectRatio = 1/pixelAspectRatio;
                newHeight = int32(oldHeight * pixelAspectRatio / refractiveIndex); % maybe refr. index needs to multiplied instead?
                newWidth = oldWidth;
            end
            if nargin > 1 % if handle and image are passed
                resImage = imresize(img, [newHeight newWidth]);
            else % if only handle is passed
                intensities = OCTFileGetIntensity(handle);
                n = size(intensities,3);
                resImages = cell(1,n);
                parfor i = 1:n, resImages{i} = imresize(intensities(:,:,i), [newHeight newWidth]); end
                resImage = resImages;
            end
        end
        
        function res = refIndexCorrection(imOrRoi, refIndex)
            height = size(imOrRoi,1);
            newWidth = size(imOrRoi,2) * refIndex;
            res = imresize(imOrRoi, [height newWidth]);
        end
        
        function mmPerPixel = getScaling(handle, image)
            props = OCTFileGetProperties(handle);
            
            % assuming that input images have been corrected for refractive
            % index already
            % in our date that means that the width of the original was
            % streched to adhere to the pixelSpacingZ
            spacingZ = str2double(props.Image.PixelSpacing.SpacingZ.Text);
            refractiveIndex = str2double(props.Acquisition.RefractiveIndex.Text);
            mmPerPixel = spacingZ/refractiveIndex;
        end
        
        function frameRate = getFrameRate(handle)
            props = OCTFileGetProperties(handle);
            frameRate = str2double(props.Acquisition.ScanTime.Text);
            frameRate = frameRate^-1;
        end
        
        
        function correctedImages = getCorrectedOCTImages(handle)
            % GETCORRECTEDOCTIMAGES  Corrects OCT image(s) for refractive index and by converting db to pixel intensities.
            %   resImages = GETCORRECTEDOCTIMAGES(handle) Applies the corrections for all images and returns them as a cell.
            %   resImage = GETCORRECTEDOCTIMAGES(handle, img) Applies the corrections to a single img but needs the handle to access the header.
            %
            %   See also correctForRefractiveIndex, DBTOPIXELINTENSITY.
            
            correctedImages = OCTPATools.dbToPixelIntensity(OCTPATools.correctForRefractiveIndex(handle));
        end
        
        
        function resImgs = dbToPixelIntensity(imgs)
            % dbToPixelIntensity Converts the OCT intensities given in db
            % to real values between 0.0 and 1.0.
            %   resImg = dbToPixelIntensity(img) Uses highest and lowest db
            %   value in single image for normalization.
            %   resImgs = dbToPixelIntensity(imgs) Finds the highest and
            %   lowest db value in all of the images (passed as a cell) for
            %   normalization.
            
            if ~iscell(imgs)
                % ...put image into a cell
                imgs = {imgs};
            end
            
            % normalization globally over all images
            darkestValue = min(min([imgs{:}]));
            brightestValue = max(max([imgs{:}]));
            parfor i = 1:length(imgs), resImgs{i} = (imgs{i} - darkestValue)/(brightestValue - darkestValue); end
            
            if length(resImgs)==1
                resImgs = resImgs{1};
            end
        end
        
        
        
        % Storing functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function saveImages(handleOrCell, path)
            %   SAVEIMAGES  (Corrects and) Saves OCT images to path.
            %   saveImages(handle, path) First corrects images using
            %   getCorrectedOCTImages and then saves them to specified path
            %   with increasing numbers as filename.
            %   saveImages(imgs, path) Saves images in cell array imgs to
            %   path.
            %
            %   See also getCorrectedOCTImages
            
            if iscell(handleOrCell)
                % assuming that you just want to save whatever is in the
                % cell
                correctedImages = handleOrCell;
            else
                % assuming input is handle and should images should be
                % corrected first
                correctedImages = OCTPATools.getCorrectedOCTImages(handleOrCell);
            end
            
            if ~exist(path)
                mkdir(path);
            end
            
            parfor i=1:length(correctedImages), imwrite(correctedImages{i}, [path, '/' , num2str(i), '.tif']); end
        end
    end
end
    
    
