function [mask] = getmask(I)
[y,x] = find(I(:,:,1) == 0 & I(:,:,2)== 255 & I(:,:,3) == 255);
a = size(I,1);
b = size(I,2);
k = zeros(a,b);
k(y,x) = 1;
subplot(2,1,1)
imshow(k)
subplot(2,1,2)
imshow(I)
end

