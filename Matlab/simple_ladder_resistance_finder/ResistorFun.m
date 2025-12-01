function EquivResistance = ResistorFun(ResistorValues, Series_or_Parallel)
%Enter the code for your function here. 
% calculate the resistance of a ladder of only parallel or only series
% resistances
a = 0;
n = size(ResistorValues,2);
switch Series_or_Parallel
    case 'S'
        EquivResistance = sum(ResistorValues);
    case 'P'
        while n > 0
            a = a + 1/ResistorValues(n) ;
            n = n - 1;
        end
        EquivResistance = a^-1;
end  
end
