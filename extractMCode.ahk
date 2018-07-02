parseData := {("(PUBLIC|EXTRN)\s+([a-zA-Z0-9@_]+)"):func("varDef")
			, ("(CONST|_DATA)\s+SEGMENT"):func("dataDef")
			, ("_TEXT\s+SEGMENT"):func("funcDef")
, ("END\R"):func("exitParse")}




/*
	WARNING:
	The coding style in this file is horrible
	With this I have warned you - I wont be held responsible for any mental damage
*/



;find public data and imported data
global publics := [] ;contain functions and global variables
global externs := [] ;contain imported functions (this should cause errors)
global functions := [] ;contains functions only (used to differentiate between global data and functions)
global binaryDataLength := 0 ;contains the current binary length of the MCode data
global dataString := "" ;contains the data as hex string
global relocations := [] ;contains the relocation data

text := FileOpen("exampleMCode.cod", "r").Read()
parse(text, parseData)
totalString := hexNr(functions.count(), 2)

for functionName, offset in functions {
	for each, character in StrSplit(functionName) {
		if !(each=1 && character="_")  ;I dont know why visual studio does this
			totalString .= hexNr(Ord(character), 1)
	}
	totalString .= hexNr(0,1)
	totalString .= hexNr(publics[functionName], 2)
	totalString .= hexNr(0, 2)
}
totalString .= hexNr(0, 2)
totalString .= hexNr(0, 2)

totalString .= hexNr(relocations.length(), 2)
For each, relocation in relocations {
	totalString .= hexNr(relocation, 2)
}
totalString .= dataString
FileOpen("output.mcode", "w").write(totalString)	

goToNextLine( byref str ) {
	StringTrimLeft, str, str, % RegExMatch(str, "\R+", val) + strLen(val) - 1
}

parse(text, parseData) {
	Try {
		Loop {
			goToNextLine := 1
			for regex, action in parseData {
				if (RegexMatch(text, "O)^" . regex, regexDat)) {
					StringTrimLeft, text, text, % regexDat.Len(0)
					goToNextLine := !%action%(text, regexDat)
					break
				}
			}
			if goToNextLine
				goToNextLine(text)
		}
	} catch e {
		if (e.message != "ending parse naturally")
			Throw e
	}
	return text
}

varDef(byref text, regex) {
	if (regex.1 = "PUBLIC") {
		publics[regex.2] := ""
	}
	else
		externs[regex.2] := ""
}

dataDef(byref text, regex) {
	s := "("
	for name, offset in publics
		if (offset == "")
			s .= name . "|"
	s := RTrim(s, "|") . ")[^a-zA-Z0-9@_]"
	parseDataData := {("(CONST|_DATA)\s+ENDS"):func("exitParse")
	,(s):func("setDataPointer")
	,("\s*(DB|DD|DQ)\s+([^\n\r]+)"):func("addData")}
	test := parse(text, parseDataData)
	text := test
}

funcDef(byref text, regex) {
	s := "("
	for name, offset in publics
		if !offset
			s .= name . "|"
	s := RTrim(s, "|") . ")\s+PROC"
	parseDataData := {("_TEXT\s+ENDS"):func("exitParse")
	,(s):func("setFuncPointer")
	,("\s+[0-9a-fA-F]{5}((?:(?:\s|\R)+(?:[0-9A-Fa-f]{2}))+\s)([^\n\r]+)"):func("addCode")}
	test := parse(text, parseDataData)
	text := test
}

exitParse(byref text, regex) {
	Throw exception("ending parse naturally")
}

setDataPointer(byref text, regex) {
	publics[regex.1] := binaryDataLength
	return 1
}

addData(byref text, regex) {
	typeLength := {DB:1, DD:4, DQ:8}[regex.1]
	dataEntries := strSplit(regex.2, ", ")
	binaryDataLength +=  typeLength * dataEntries.length()
	for each, entry in dataEntries {
		if (RegexMatch(entry, "0([a-fA-F0-9]+)", data)) {
			data1 := Format("{:0" . typeLength*2 . "s}", data1)
			Loop % typeLength {
				if (A_Index)
				byte := Format("{:02s}",subStr(data1, (typeLength-A_Index)*2 + 1, 2))
				dataString .= byte
			}
		} else if (RegExMatch(entry, "'([^']+)'", data)) {
			dataLength := dataLength := min(strLen(data1), typeLength)
			Loop % dataLength {
				byte := Format("{:02x}",Ord(subStr(data1, A_Index, 1)))
				dataString .= byte
			}
		}
	}
}


setFuncPointer(byref text, regex) {
	publics[regex.1]   := binaryDataLength
	functions[regex.1] := 1
	return 1
}

addCode(byref text, regex) {
	data := RegExReplace(regex.1, "\s|\R")
	s := "PTR\s*("
	for name, offset in publics {
		if !(offset == "")
			s .= "\Q" name . "\E|"
	}
	s := RTrim(s, "|") . ")([^a-zA-Z0-9@_$]|$)"
	
	if (RegexMatch(regex.2, s, reference)) {
		while (!mod( pos := inStr(data, "00000000", true, A_Index), pos+1 ))
			if (A_Index > 1000 )
				Msgbox % regex.0 . text
		pointerStr := Format("{:08x}", publics[reference1])
		data1 := subStr(data, 1, pos-1)
		relocations.Push( Round(strLen(data1)/2) + binaryDataLength )
		data2 := ""
		data3 := subStr(data, pos+8)
		Loop 4 {
			data2 .= subStr(pointerStr, 9-A_Index*2, 2)
		}
		data := data1 . data2 . data3
	}
	dataString .= data
	binaryDataLength +=  Round(strLen(data)/2)
}

hexNr(nr, byteSize) {
	result := Format("{:0" byteSize * 2 "x}", nr)
	s := ""
	Loop % byteSize {
		s .= SubStr(result, (byteSize- A_Index)*2+1, 2)
	}
	return s
}