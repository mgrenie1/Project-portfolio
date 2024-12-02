import csv
import os
import sys 
import math
import cmath
import numpy as np

def makeList(text): #Changes input from multiple lines to a list of each line and removes \n and empty lines
    inputLine = []
    for line in text:
        line = line.replace("\n", "") #Removes instances of "\n"
        #If statement removes commented lines.
        if "#" not in line:
            inputLine.append(line) #no hashtag = append line to list inputLines
        else:
            inputLine.append(line[:line.find("#")]) #if there is a hashtag only append whatever is before it to l§ist inputLines
    inputLine = list(filter(None, inputLine)) #remove empty lines
    return inputLine


def findBlocks(input, header, counter): #used to extract Input, Terms and Output blocks individually
    for line in input:
        if str('<'+ header +'>') in line: #when header found, store the index in min.
            min = counter
        elif str('</'+ header +'>') in line: #when footer found, store the index in max.
            max = counter
        else:
            counter=counter+1  #if neither found, continue searching
    return input[min+1:max+1] #return the data between the header and footer.


def findTerms(input, targets):
    terms = []
    for target in targets: #for each possible term try to find a value and append it to terms
        found = 0
        for i in input:
            i = i.split(" ") #split parameters that are in the same index of the list into substrings
            for IinI in i: #for each substring
                if target in IinI: #if the terms we are looking for is in the substring append it to terms
                    equals = IinI.find("=")
                    terms.append(float(IinI[equals+1:]))
                    found = 1
                    break
            if found:
                break
        if not found:
            terms.append("Empty") #if the term is not in the list append "Empty" to the terms list
    return terms


def findOutputs(input, targets):
    outputs = []
    for i in input: #for each possible term try to find a value and append it to terms
        for target in targets: #for each target
            if target in i and " " in i: #if the target is found
                i = i[i.find(" ")+1:].replace(" ","") #remove all spaces after the units
                output = [target, i[i.find(" ")+1:]] #save the output variable and units
                if output[1] == "":
                    output[1] = "L" #if there is not unit given save units as "L"
                outputs.append(output)
                break
            elif target in i: 
                outputs.append([target, "L"]) #if only target in i then save units as "L"
                break
    return outputs


def thevenify(input):
    if not(input[3] == "Empty") and (input[1] == "Empty"): #if circuit has a norton source convert it to a thevenin source
        if not(input[2] == "Empty"):
            input[1] = float(input[3])*float(input[2])
        else:
            input[1] = float(input[3])*(1/float(input[4]))
    return input


def formatHeader(outputVars):
    vars = ["      Freq"] #format frequency and Hz part of output file
    units = ["        Hz"]
    for i in outputVars: #for each variable format the real and imaginary part
        if not("dB" in i[1]):
            realPart = "Re(" + i[0] + ")" #prepare a part for the real and imaginay outputs
            imagPart = "Im(" + i[0] + ")"
        else:
            realPart = "|" + i[0] + "|"
            imagPart = "/_" + i[0]
        extraSpace = 11-len(realPart) #calculate number of spaces needed for column to be right width
        space = ""
        for x in range(extraSpace): #generate whitespace for column
            space = space + " "
        vars.append(space+realPart) #append formatted variable names
        vars.append(space+imagPart)
        unit = i[1]
        extraSpace = 11-len(unit) #calculate number of spaces for column to be right width
        space = ""
        for x in range(extraSpace): #generate whitespace
            space = space + " "
        units.append(space+unit) #append unit names
        if "dB" in i[1]:
            units.append("       Rads")
        else:
            units.append(space+unit)
    return vars,units


def findfreqs(start,end,n,terms):
    if not("LF" in terms[2]):
        increment = (end-start)/(n-1) #calculate the increment between each frequency
        freqs = []
        while (start<=end):
            freqs.append(start)
            start = start+increment #calculate each frequency and append it to freqs
    else:
        bottom = math.log(start,10) #find smallest power
        top = math.log(end,10)  #find largest power
        increment = (top-bottom)/(n-1)  #find size of power increment
        freqs = [] #initialise output array
        while (start<=end):
            freqs.append(start) #begin adding frequencies
            start = pow(10,(math.log(start,10)+increment)) #generate next logarithmic frequency
    return freqs

def unitPrefix(input):
    print(input)
    if "Ohms" in input:
        input = input.replace("Ohms", "")
    print(input)
    if "p" in input:
        return 1000000000000
    elif "n" in input:
        return 1000000000
    elif "u" in input:
        return 1000000
    elif "m" in input:
        return 1000
    elif "k" in input:
        return 0.001
    elif "M" in input:
        return 0.000001
    elif "G" in input:
        return 0.000000001
    else:
        return 1


def sortRes(input,freq): #sort the components in the right order
    i = 1
    Y = []
    Z = []
    stop = True
    while True:
        seriesValue = 0
        stop = True
        for x in input:
            n1 = x.find("n1=") #first node  
            n2 = x.find("n2=") #second node
            component = x[x.find(" ",n2)+1] #component value
            if (int(x[n1+3:x.find(" ",n1)]) == i) and (int(x[n2+3]) == 0): #if component is in series
                stop = False
                Z.append(0) 
                if component == "R": #calculate the impedance for the parallel component for a resistor
                    componentValue = 1/complex(float(x[x.find(component)+2:]),0)
                    Y.append(componentValue)
                elif component == "G": #for a component with acceptance
                    componentValue = complex(float(x[x.find(component)+2:]),0)
                    Y.append(componentValue)
                elif component == "C": #for a capacitor
                    componentValue = 1/complex(0,-1/(2*math.pi*float(x[x.find(component)+2:])*freq))
                    Y.append(componentValue)
                else:
                    componentValue = 1/complex(0,2*math.pi*float(x[x.find(component)+2:])*freq)
                    Y.append(componentValue) #for an inductor
            elif int(x[n1+3:x.find(" ",n1)]) == i: #if component is in parallel
                stop = False
                if component == "R": #for a resistor
                    seriesValue = complex(float(x[x.find(component)+2:]),0)
                elif component == "G": #for a component with acceptance
                    seriesValue = complex(1/float(x[x.find(component)+2:]),0)
                elif component == "C": #for a capacitor
                    seriesValue = complex(0,-1/(2*math.pi*float(x[x.find(component)+2:])*freq))
                else: #for an inductor
                    seriesValue = complex(0,2*math.pi*float(x[x.find(component)+2:])*freq)
        i += 1
        Y.append(0)
        Z.append(seriesValue)
        if stop: #if all the components are accounted for take 
            return Y,Z
        

def reduceMatrix(Y,Z): #reduce the ABCD matrices into one matrix
    matrix = np.array([[1, Z[0]],[Y[0], 1]],dtype = np.clongdouble)
    for i in range(len(Y)-1):
        nextVals = np.matrix([[1, Z[i+1]],[Y[i+1], 1]],dtype = np.clongdouble)
        matrix = np.matmul(matrix,nextVals)
    return matrix.A1


def getOutputs(A,B,C,D,SourceV,LoadR,SourceR,SourceG,outputVars):
    outputs = []
    if SourceR != 'Empty': #if the source load is in series
        Zout = (D*SourceR+B)/(C*SourceR+A) #calculate Zout
    else: #if the source load is in parallel
        Zout = (D*(1/SourceG)+B)/(C*(1/SourceG)+A) #calculate Zout
    Zin = (A*LoadR+B)/(C*LoadR+D) #calculate Zin
    if SourceR != 'Empty':
        Vin = SourceV*Zin/(Zin+SourceR) #calculate Vin
    else:
        Vin = SourceV*Zin/(Zin+(1/SourceG)) #calculate Vin
    Av = 1/(A+B*(1/LoadR)) #calculate Av
    Vout = Vin*Av #calculate Vout
    Iin = Vin/Zin #calculate Iin
    Iout = Vout/LoadR #calculate Iout
    Ai = 1/(C*LoadR+D) #calculate Ai
    Pin = Vin*Iin.conjugate() #calculate Pin
    Ap = Av*Ai.conjugate() #calculate Ap
    Pout = Pin*Ap #calculate Pout
    for i in outputVars: #fill out the matrix of output values
        if "Zout" in i:
            outputs.append(Zout*unitPrefix(i[1]))
        elif "Zin" in i:
            outputs.append(Zin*unitPrefix(i[1]))
        elif "Vin" in i:
            if "dBV" in i:
                abs = 20*np.log10(np.absolute(Vin))
                angle = cmath.phase(Vin)*1j
                Vin = abs + angle
            outputs.append(Vin*unitPrefix(i[1]))
        elif "Av" in i:
            if "dB" in i:
                abs = 20*np.log10(np.absolute(Av))
                angle = cmath.phase(Av)*1j
                Av = abs + angle
            outputs.append(Av*unitPrefix(i[1]))
        elif "Vout" in i:
            if "dBV" in i:
                abs = 20*np.log10(np.absolute(Vout))
                angle = cmath.phase(Vout)*1j
                Vout = abs + angle
            outputs.append(Vout*unitPrefix(i[1]))
        elif "Iin" in i:
            if "dBA" in i:
                abs = 20*np.log10(np.absolute(Iin))
                angle = cmath.phase(Iin)*1j
                Iin = abs + angle
            outputs.append(Iin*unitPrefix(i[1]))
        elif "Iout" in i:
            if "dBA" in i:
                abs = 20*np.log10(np.absolute(Iout))
                angle = cmath.phase(Iout)*1j
                Iout = abs + angle
            outputs.append(Iout*unitPrefix(i[1]))
        elif "Ai" in i:
            if "dB" in i:
                abs = 20*np.log10(np.absolute(Ai))
                angle = cmath.phase(Ai)*1j
                Ai = abs + angle
            outputs.append(Ai*unitPrefix(i[1]))
        elif "Pin" in i:
            if "dBW" in i:
                abs = 10*np.log10(np.absolute(Pin))
                angle = cmath.phase(Pin)*1j
                Pin = abs + angle
            outputs.append(Pin*unitPrefix(i[1]))
        elif "Pout"in i:
            if "dBW" in i:
                abs = 10*np.log10(np.absolute(Pout))
                angle = cmath.phase(Pout)*1j
                Pout = abs + angle
            outputs.append(Pout*unitPrefix(i[1]))
    return outputs


def splitAns(outputValues, freq): #splits answers into real and imaginary values
    splitOutput = []
    splitOutput.append(freq) #append the frequency because it can only have a real component
    for i in outputValues:
        splitOutput.append(i.real) #split the real and imaginary components and append them
        splitOutput.append(i.imag)
    return splitOutput


def formatOutput(outputs): #format outputs into lines to fill the output csv file
    freq = 1
    counter = 0
    for i in outputs: #for each output
        i = str(i)
        if i[0] == "-": #if there is a minus sign add one less space 
            space = ""
        else:
            space = " "
        if freq: #freq needs one less space than the other values
            freq = 0
            outputs[0] =  " " + str("{:.3e}".format(float(i))) #round to 4 sig.figs
        else:
            outputs[counter] = " " + space + ("{:.3e}".format(float(i)))
        counter += 1
    return outputs


try:
    os.system("clear")
    inputFile = open(sys.argv[1], 'r') #opens input file from cmd
    inputLines = inputFile.readlines() #extracts lines
    cleanData = makeList(inputLines) #puts all lines into a list
    outputOptions = ["Vin","Vout","Iin","Iout","Pin","Zout","Pout","Zin","Av","Ai"] #defining available input options
    termOptions = ["RL", "VT", "RS", "IN", "GS", "Fstart", "Fend", "Nfreqs"] #defining available terms
    counter = 0 #this counter allows the code to skip lines that have already been parsed through
    circuit = findBlocks(cleanData, "CIRCUIT", counter) #save the data about the circuit from the input file
    terms = findBlocks(cleanData, "TERMS", counter) #save the data about the terms from the input file
    outputs = findBlocks(cleanData, "OUTPUT", counter) #save the data about the outputs form the input file
    termsOnly = findTerms(terms, termOptions) #returns list of the values of the terms given in the correct order
    outVars = findOutputs(outputs,outputOptions) #returns list of output variables and units given in correct order
    standardTerms = thevenify(termsOnly) #convert norton sources to thevenin sources
    vars,units = formatHeader(outVars) #formats variables and units to correct format to later be added to output csv file
    frequencies = findfreqs(termsOnly[5],termsOnly[6],termsOnly[7],terms) #find the frequencies that need to be analysed
    
    with open(sys.argv[2], 'w', newline = "") as file:
        pen = csv.writer(file)
        pen.writerow(vars)
        pen.writerow(units)
        for f in frequencies: #calulation loop for each frequency
            Y,Z = sortRes(circuit,f) #sort circuit components into the right order
            A,B,C,D = reduceMatrix(Y,Z) #merge all ABCD matrices into one
            outputVals = getOutputs(A,B,C,D,standardTerms[1],standardTerms[0],standardTerms[2],standardTerms[4],outVars)
            #calculate output variables and return them in the right order
            splitOutputs = splitAns(outputVals,f) #split output variables into real and imaginary values
            outputLine = formatOutput(splitOutputs) #format a line of results to be printed to output csv file 
            outputLine.append("") #adds whitespace for formatting
            pen.writerow(outputLine) #write row of values to ouptut csv file
    
    
except: #if any part of the code fails
    with open(sys.argv[2], 'w', newline='') as newfile: #return empty csv file as requested in brief
        pen = csv.writer(newfile)

