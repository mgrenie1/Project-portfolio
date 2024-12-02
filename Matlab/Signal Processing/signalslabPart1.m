%{
n = 0:99;
input = cos(2*pi*0.1*n);
coefficients = [1/3,1/3,1/3];
y = conv(input,coefficients);
plot(input, 'b*-')
hold on
plot(y, 'r.-')
%}
%{
b = [1/3,1/3,1/3];
omega = -pi:pi/100:pi;
H = freqz(b,1,omega);
plot(omega,angle(H))
xlabel('Normalized frequency, \omega')
ylabel('Gain')
%}
%{
[Input,Output] = PartA_Gen(11370);
Nout = length(Output);
Nin = length(Input);
inputspectrum = abs(fft(Input)*2/Nin); 
outputspectrum = abs(fft(Output)*2/Nout); 
plot(inputspectrum)
hold on
plot(outputspectrum)
ratio = max(Output)/max(Input);
%}

clearvars
[time,message] = PartB_Gen(11370);
t = -10000:1:10000;
Fs = 2000;
N = length(message);
spectrum = fft(message); 
hold on
subplot(3,4,1)
plot(time,message)
title("input")
subplot(3,4,2)
plot(Fs/N*(0:N-1),abs(spectrum),"LineWidth",3)
xlabel("f (Hz)")
ylabel("|fft(X)|")
title("frequency spectrum")
c1 = 0.4838;
c2 = 0.421;
c1real = 134*2*pi/2000;
c2real = 154*2*pi/2000;
window = hamming(800)';
subplot(3,4,3)
plot(window)
title("Hamming window")
lowpass = (c1real/pi)*sinc((c1real/pi)*t);
highpass = -(c2real/pi)*sinc((c2real/pi)*t);
bandpass = lowpass+highpass;
subplot(3,4,5)
plot(t,lowpass)
title("lowpass")
subplot(3,4,6)
plot(t,highpass)
title("highpass")
subplot(3,4,7)
plot(t,bandpass)
title("bandpass")
bandpass = [zeros(1,400),bandpass(1:19601)];
bandpass = bandpass(1,10001:10800);
filterfinal = window.*bandpass;
subplot(3,4,8)
plot(filterfinal)
title("windowed filter")
output = conv(filterfinal,message);
output = output(800:end);
normout = abs(output/max(output));
subplot(3,4,9)
plot(time,output)
title("output")
subplot(3,4,10)
plot(time,normout)
title("normalized output")
clearvars;
[time,message] = PartB_Gen(11370);
sidebands = [134, 154];
Fs = 2000;
y = bandpass(message, sidebands, Fs);
subplot(3,4,11)
plot(time,y)
title("output using Matlab function")
hold off
