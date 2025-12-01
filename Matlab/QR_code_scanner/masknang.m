function [ultimask,angle] = masknang(I)
cyanMask = I(:,:,3) > I(:,:,1) & I(:,:,3) == I(:,:,2);
onlycyan = I;
onlycyan(repmat(~cyanMask,[1 1 3])) = 0;
redMask = I(:,:,3) ==0 & I(:,:,1) == 255 & I(:,:,2) == 0;
onlyred = I;
onlyred(repmat(~redMask,[1 1 3])) = 0;
ultimask = onlyred+onlycyan;
maskflag = 0;
for ux = 1:size(ultimask,2)
    for uy = 1:size(ultimask,1)
        if [I(uy,ux,1) I(uy,ux,2) I(uy,ux,3)] == [0 255 255] & [I(uy,ux+1,1) I(uy,ux+1,2) I(uy,ux+1,3)] == [255 0 0]|[I(uy,ux,1) I(uy,ux,2) I(uy,ux,3)] == [0 255 255] & [I(uy,ux+2,1) I(uy,ux+2,2) I(uy,ux+2,3)] == [255 0 0]
            toplout = [uy ux];
            maskflag = 1;
            break
        end
    end
    if maskflag == 1
        break
    end
end
maskflag = 0;
for uy = 1:size(ultimask,1)
    for ux = 1:size(ultimask,1)
        if [I(uy,ux,1) I(uy,ux,2) I(uy,ux,3)] == [0 255 255] & [I(uy+1,ux,1) I(uy+1,ux,2) I(uy+1,ux,3)] == [255 0 0]|[I(uy,ux,1) I(uy,ux,2) I(uy,ux,3)] == [0 255 255] & [I(uy+2,ux,1) I(uy+2,ux,2) I(uy+2,ux,3)] == [255 0 0]
            toprout = [uy ux];
            maskflag = 1;
            break
        end
    end
    if maskflag == 1
        break
    end
end
angle = tan((toplout(1)-toprout(1))/(toprout(2)-toprout(1)))*360/(2*pi);
end

