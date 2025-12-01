function [Composite]=flexibleGreenScreen(foregd_fname,backgd_fname,newSize,newPosition)
foregd_im = imread(foregd_fname);
backgd_im = imread(backgd_fname);
newForegd = create_newForegd(foregd_im,newSize);
Mask = create_image_mask(newForegd,newSize,newPosition);
Composite = create_composite(backgd_im,Mask,newPosition,newForegd);

%imshow(cutout)
%for x = 1:size(backgd_im,2)
%    for y = 1:size(backgd_im,1)
%        if cutout(y,x,:) == [0 0 0]
%           Composite(y,x,:) = newForegd(y,x,:);
%        end
%    end
%end

end

% insert your subfunctions here, e.g. create_image_mask & is_green
function [newForegd] = create_newForegd(foregd_im,newSize)
newForegd = resize_image(foregd_im,newSize(1,2), newSize(1,1));
end

function [Mask] = create_image_mask(newForegd,newSize,newPosition)
% insert your code for the create_image_mask here
z = zeros(size(newForegd,1),size(newForegd,2),3);
for x = 1:size(newForegd,2)
    for y = 1:size(newForegd,1)
        z(y,x,:) = is_green(newForegd(y,x,:));        
    end
end
Mask = uint8(z);
lengthAdj = [ones(size(Mask,1),newPosition(1,2),3), Mask];
Mask = uint8([ones(newPosition(1,1),size(lengthAdj,2),3);lengthAdj]);
end

function [cutout] = create_composite(backgd_im,Mask,newPosition,newForegd)
cutout = backgd_im;
for x = 1:size(Mask,2)
    for y = 1:size(Mask,1)
        if Mask(y,x,:) == [0 0 0]
            cutout(y,x,:) = newForegd(y-newPosition(1,1),x-newPosition(1,2),:);
        end
    end
end 
end

function  [isG] = is_green(Pixel_RGB_vector)
% you should insert your code for the is_green function here (if you call it in the create_image_mask function)
if Pixel_RGB_vector(1,2) > Pixel_RGB_vector(1,1) + Pixel_RGB_vector(1,3)
    isG = 1;
else
    isG = 0;
end
end
