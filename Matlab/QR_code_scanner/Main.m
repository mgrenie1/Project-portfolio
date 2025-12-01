clear all
close all
im = imread("code4seen2.jpg");
out = decodeRotatedColour(im);
fprintf("The hidden message is: %s\n", out);