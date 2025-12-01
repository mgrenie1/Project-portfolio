function [code]=decodeRotatedColour(I)
% insert your code here
[crop,mask,ang] = masknang(I);
Matrix = imageRotate(crop,ceil(ang)+3);
cropped = cropmore(Matrix);
croppedround = rounder(cropped);
croppedbw = bw(croppedround);
QRonly = findQR(croppedbw);
code = decode(QRonly);
subplot(2,4,1)
imshow(I)
subplot(2,4,2)
imshow(mask)
subplot(2,4,3)
imshow(Matrix)
subplot(2,4,4)
imshow(cropped)
subplot(2,4,5)
imshow(croppedround)
subplot(2,4,6)
imshow(croppedbw)
subplot(2,4,7)
imshow(QRonly)
end
% insert your subfunctions here
function [Matrix] = bw(input)
for x = 1:size(input,2)
    if any(input(:,x,2) == 255) && ~(input(round(size(input,1))/2,x,2) == 255 && input(round(size(input,1))/2,x,1) == 255)
        input(:,x,1) = 255; 
        input(:,x,2) = 0;
        input(:,x,3) = 0;
    else 
        break
    end
end
for x = size(input,2):-1:1
    if any(input(:,x,2) == 255) && ~(input(round(size(input,1))/2,x,2) == 255 && input(round(size(input,1))/2,x,1) == 255)
        input(:,x,1) = 255; 
        input(:,x,2) = 0;
        input(:,x,3) = 0;
    else 
        break
    end
end
for y = 1:size(input,1)
    if any(input(y,:,2) == 255) && ~(input(y,round(size(input,2)/2),2) == 255 && input(y,round(size(input,2)/2),1) == 255)
        input(y,:,1) = 255; 
        input(y,:,2) = 0;
        input(y,:,3) = 0;
    else 
        break
    end
end
for y = size(input,1):-1:1
    if any(input(y,:,2) == 255) && ~(input(y,round(size(input,2)/2),2) == 255 && input(y,round(size(input,2)/2),1) == 255)
        input(y,:,1) = 255; 
        input(y,:,2) = 0;
        input(y,:,3) = 0;
    else 
        break
    end
end
Matrix = input(:,:,1);
end
function [Matrix] = rounder(input)
smaller = input/255;
Matrix = round(smaller);
Matrix = Matrix*255;
end
function [Matrix] = cropmore(input)
y = 1;
for x1 = 1:size(input,2)
    if input(y,x1,1) > 180 && input(y,x1,2) < 90 && input(y,x1,3) < 90
        topr = [y x1];
        break
    end
    y = y+1;
end
Matrix = input(topr(1):size(input,1)-topr(1),topr(2):size(input,2)-topr(2),:);
end

function [crop,ultimask,angle] = masknang(I)
cyanMask = I(:,:,3) > I(:,:,1) & I(:,:,2) > I(:,:,1) & I(:,:,2) > 180 & I(:,:,3) > 180 & I(:,:,1) < 90;
onlycyan = I;
onlycyan(repmat(~cyanMask,[1 1 3])) = 0;
redMask = I(:,:,1) > 180 & I(:,:,2) < 90 & I(:,:,3) < 90;
onlyred = I;
onlyred(repmat(~redMask,[1 1 3])) = 0;
ultimask = onlyred+onlycyan;
maskflag = 0;
xindices = [];
yindices = [];
Matrix = I;
for cropx = 1:size(ultimask,2)
    red = find(ultimask(:,cropx,1) > 180 & ultimask(:,cropx,2) < 70 & ultimask(:,cropx,3) < 70,1);
    cyan = find(ultimask(:,cropx,1) < 90 & ultimask(:,cropx,2) > 180 & ultimask(:,cropx,3) > 180,1);
    if isempty(red) || isempty(cyan)
        xindices = [xindices cropx];
    end
end
for cropy = 1:size(ultimask,1)
    red = find(ultimask(cropy,:,1) > 180 & ultimask(cropy,:,2) < 70 & ultimask(cropy,:,3) < 70,1);
    cyan = find(ultimask(cropy,:,1) < 90 & ultimask(cropy,:,2) > 180 & ultimask(cropy,:,3) > 180,1);
    if isempty(red) || isempty(cyan)
        yindices = [yindices cropy];
    end
end
xdiff = [0 diff(xindices)];
ydiff = [0 diff(yindices)];
[mx,maxdifx] = max(xdiff);
[my,maxdify] = max(ydiff);
maxxidx = xindices(maxdifx-1);
maxyidx = yindices(maxdify-1);
crop = I(maxyidx:maxyidx+my,maxxidx:maxxidx+mx,:);
cropmask = ultimask(maxyidx:maxyidx+my,maxxidx:maxxidx+mx,:);
blackr = all(cropmask == 0 ,2);
blackr = blackr(:,:,1);
blackc = all(cropmask == 0 ,1);
blackc = blackc(:,:,1);
cropmask = cropmask(~blackr,~blackc,:);
crop = crop(~blackr,~blackc,:);
for xidx = 1:size(crop,2)
    if cropmask(1,xidx,1) < 180 && cropmask(1,xidx,2) > 200 && cropmask(1,xidx,3) > 200
        top = [1 xidx];
        break
    end
end
for yidx = 1:size(crop,1)
    if cropmask(yidx,1,1) < 180 && cropmask(yidx,1,2) > 200 && cropmask(yidx,1,3) > 200
        left = [yidx 1];
    end
end
angle = atan((top(2)-left(2))/(left(1)-top(1)))*360/(2*pi);
end

function [Matrix] = findQR(I)
xl = size(I,2);
yl = size(I,1);
for x = round(xl/2):-1:1
    if sum(I(:,x,1))/255 == yl
        left = x;
        break
    end
end
for y = round(yl/2):-1:1
    if sum(I(y,:,1))/255 == xl
        top = y;
        break
    end
end
for y1 = round(yl/2):yl
    if sum(I(y1,:,1))/255 == xl
        bot = y1;
        break
    end
end
for x1 = round(xl/2):xl
    if sum(I(:,x1,1))/255 == yl
        right = x1;
        break
    end
end
rot = 0;
if left>top
    rot = 1;
    top = yl-bot;
elseif left>yl-bot
    rot = 3;
    bot = top;
elseif left>xl-right
    rot = 2;
    right = left;
else 
    left = xl-right;
end
rotted = rot90(I,rot);
Matrix = rotted(top:bot,left:right);
end

function [code] = decode(Matrix)
sqsize = round(size(Matrix,1)/10);
binval = "";
for x = round(sqsize/2):sqsize:size(Matrix,2)
    for y = round(sqsize/2):sqsize:size(Matrix,1)
        binval = [binval,string(Matrix(y,x))];
    end
end
binval = strrep(binval,"255","1");
binval(1) = [];
intval = "";
for x = 1:8
    intval = append(intval,binval(x));
end
numel = bin2dec(intval);
bytes = [];
byte = "";
for x = 1:numel
    for y = 1:8
        byte = append(byte,binval(x*8+y:x*8+y));
    end
    bytes = [bytes byte];
    byte = "";
end
decval = bin2dec(bytes);
code = char(decval);
end

