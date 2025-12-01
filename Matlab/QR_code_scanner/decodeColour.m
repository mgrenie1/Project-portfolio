function [code] = decodeColour(I)
a = size(I,2);
l = size(I,1);
flag = 0;
for x = 1:a
    for y = 1:l
    if [I(y,x,1) I(y,x,2) I(y,x,3)] == [0 255 255] & [I(y,x+1,1) I(y,x+1,2) I(y,x+1,3)] == [255 0 0]
        toplrc = [y x];
        for n = (toplrc(2)+1):a
            if [I(y,n,1) I(y,n,2) I(y,n,3)] == [255 255 255]
                topl = [y n];
                break
            end
            y = y + 1;
        end
        for  j = topl(2):a
            if [I(y,j,1) I(y,j,2) I(y,j,3)] == [255 255 255] & [I(y,j+1,1) I(y,j+1,2) I(y,j+1,3)] == [255 0 0]
                topr = [y j];
                flag = 1;
                break
            end
        end
    end
    if flag == 1
        break
    end
    end
    if flag == 1
        break
    end
end
sizeQR = topr(2) - topl(2);
botl = topl + [sizeQR 0];
Matrix = I(topl(1):botl(1),topl(2):topr(2));
for x = 1:sizeQR+1
    for y = 1:sizeQR+1
        if Matrix(y,x) == 255
            Matrix(y,x) = 1;
        end
    end
end
code = decode(Matrix);
end

function [code]=decode(I)
% insert your code here
[rot,sqsize,borderlen] = wheresquare(I);
Matrix = cutI(I,rot,sqsize,borderlen);
binval = [];
intval = [];
numel = bin2int(Matrix(1:8,1));
for x = 1:size(Matrix,2)
    for y = 1:size(Matrix,1)
        if x > 1
            if length(binval)<7
               binval(length(binval)+1) = Matrix(y,x);
            else
               binval(length(binval)+1) = Matrix(y,x);
               intval = [intval bin2int(binval)];
               binval = [];
            end
        elseif y > 8 
            if length(binval)<8 
                binval(length(binval)+1) = Matrix(y,x);
            else
                intval = [intval bin2int(binval)];
                binval = [];
            end
        
        end
    end
end
intval = intval(1,1:numel);
code = char(intval);
end

% insert your subfunctions here
function [intval] = bin2int(binval)
intval = 0;
a = length(binval);
for d = 1:length(binval)
    if binval(d) == 1
        k = (a-d);
        intval = intval+2^k;
    end
end
end
function [Matrix] = cutI(input,rot,sqsize,borderlen)
turnI = rot90(input,rot);
Matrix = turnI(borderlen+1:sqsize:end-borderlen,borderlen+1:sqsize:end-borderlen);
end
function [rot,sqsize,borderlen] = wheresquare(input)
ytop = 0;
ybot = 0;
xright = 0;
xleft = 0;
x = size(input,2);
sqsize = 0;
for k = 1:x
    if sum(input(k,:)) == x
        if k < x/2
            ytop = ytop + 1;
        else 
            ybot = ybot + 1;
        end
    end
    if sum(input(:,k)) == x
        if k < x/2
            xleft = xleft + 1;
        else 
            xright = xright + 1;
        end
    end
end
if ybot == ytop
    borderlen = ybot;
elseif ybot == xright
    borderlen = ybot;
elseif ybot == xleft
    borderlen = ybot;
else 
    borderlen = xright;
end
if ybot == min([ybot ytop xright xleft])
    rot = 3;
    mindim = sum(input(x-ybot-1,:));
elseif ytop == min([ybot ytop xright xleft])
    rot = 1;
    mindim = sum(input(ytop+1,:));
elseif xright == min([ybot ytop xright xleft])
    rot = 2;
    mindim = sum(input(:,x-xright-1));
else
    rot = 0;
    mindim = sum(input(:,xleft+1));
end
squarestart = min([ybot ytop xright xleft])+1;
if rot == 0
    for k = squarestart:x
        if sum(input(:,k)) == mindim
            sqsize = sqsize + 1;
        else
            break
        end
    end
elseif rot == 1
    for k = squarestart:x
        if sum(input(k,:)) == mindim
            sqsize = sqsize + 1;
        else
            break
        end
    end
elseif rot == 2
    for k = squarestart:x
        if sum(input(:,x-k)) == mindim
            sqsize = sqsize + 1;
        else
            sqsize = sqsize + 1;
            break
        end
    end
elseif rot == 3
    for k = squarestart:x
        if sum(input(x-k,:)) == mindim
            sqsize = sqsize + 1;
        else
            sqsize = sqsize + 1;
            break
        end
    end
end
end
