function [frequencies] = DecodeData(t,y)
% insert your code here
[ts,ss] = mysortdata(t,y);
NoPoints = 37;
[t_smooth,y_smooth] = mysmoothdata(ts,ss,NoPoints);
t_step = 0.01;
[t_interp,y_interp]=myinterpolatedata(t_smooth,y_smooth,t_step);
[f,relaP] = calcFFT(t_interp,y_interp);
peaks = zeros(1,3);
freq = zeros(1,3);
for fi = 1:3
    maxP = 0;
    for idx = 2:1:size(relaP,2)-1
       if relaP(idx)>relaP(idx+1) && relaP(idx)>relaP(idx-1) && all(f(idx) ~= freq)
          if relaP(idx)>maxP
           maxP = relaP(idx); 
           maxF = f(idx);
          end
       end
    end
    peaks(fi) = maxP;
    freq(fi) = maxF;
end
for k = 1:3
    if peaks(k) > 0.2
        frequencies(k) = freq(k);
    end
end
end

% insert your subfunctions here

function [t_smoothed,y_smoothed]=mysmoothdata(t,y,NoPoints)
% insert your code here
y_smoothed = y;
t_smoothed = t;
for x = 1:size(y,2)
    if x-((NoPoints-1)/2)<=0
        n = length(y)-(length(y)-x+1);
        y_smoothed(x) = (1/(2*(n)+1))*sum(y(x-n:x+n));
    elseif ((NoPoints-1)/2)+x>length(y)
        m = (length(y)-x);
        y_smoothed(x) = (1/(2*(m)+1))*sum(y(x-m:x+m));
    else 
        y_smoothed(x) = (1/(NoPoints))*sum(y(x-((NoPoints-1)/2):x+((NoPoints-1)/2)));
    end
end
end
function [t_interpolated,y_interpolated]=myinterpolatedata(t,y,t_step)
% insert your code here
tmax = max(t);
tmin = min(t);
numt = (tmax-tmin)/t_step;
t_interpolated = [linspace(tmin,tmax,numt+1) tmax];
is_equal = ismember(t_interpolated,t);
for x = length(t_interpolated)
    if is_equal(x) == 1
        t_interpolated(x) = [];
    end
end
y_interpolated = interp1(t,y,t_interpolated);
end
function [time_sorted,signal_sorted]=mysortdata(time,signal)
%insert your code here
time_sorted = time;
signal_sorted = signal;
for x = 1:length(time)
    for y = 1:length(time)-x
        if time_sorted(y)>time_sorted(y+1)
            t = time_sorted(y);
            t1 = time_sorted(y+1);
            s = signal_sorted(y);
            s1 = signal_sorted(y+1);
            time_sorted(y) = t1;
            signal_sorted(y) = s1;
            time_sorted(y+1) = t;
            signal_sorted(y+1) = s;
        end
    end
end

end