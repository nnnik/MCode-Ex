class VSCompiler {
	
	static compileBatString := "CALL {1:s}`r`ncl {2:s} /O1x /FAcu /TC /c /arch:SSE2"
	
	setInputFile(file) {
		this.inputFile := file
	}
	
	getOutputFile() {
		return RegExReplace(this.inputFile, "\.[^.]+$") . ".cod"
	}
	
	compile(bitness := "32") {
		compileString := Format(this.compileBatString, this.getVSBat()[bitness], this.inputFile)
		exec := this.runWaitMany(compileString)
		if inStr(exec, "Error") {
			Msgbox % exec
		}
		compiledText := fileOpen(this.getOutputFile(), "r").read()
		compileResult := this.initializeCompileResult()
		parseClass := this.AssemblyListingParser
		parser := new parseClass(compiledText, compileResult, bitness)
		parser.parse()
		return compileResult
	}
	
	initializeCompileResult() {
		return new CompileResult()
	}
	
	getVSBat() {
		baseVisualStudioFolder := "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise"
		batPath := "\VC\Auxiliary\Build\vcvarsall.bat"
		return 	{ 32:"""" . baseVisualStudioFolder . batPath . """ x86"
		, 64:"""" . baseVisualStudioFolder . batPath . """ x86_amd64"}
	}
	
	class AssemblyListingParser {
		
		static mainParseData := {("(PUBLIC|EXTRN)\s+([a-zA-Z0-9@_]+)"):"addReference"
		, ("(CONST|_DATA|_BSS)\s+SEGMENT"):"addDataSegment"
		, ("_TEXT\s+SEGMENT"):"addFunctionSegment"
		, ("END\R"):"exitParse"}
		
		__New(text, compileResult, bitness := 32) {
			this.compileResult := compileResult
			this.text := text
			this.ptrSize := {32:4, 64:8}[bitness]
		}
		
		parse() {
			this.matchParseData(this.text, this.mainParseData)
			return this.compileResult
		}
		
		matchParseData(text, parseData) {
			Loop {
				goToNextLine := 1
				for regex, action in parseData {
					if (RegexMatch(text, "O)^" . regex, regexDat)) {
						text := subStr(text, regexDat.Len(0)+1)
						if (action = "exitParse")
							break, 2
						goToNextLine := !this[action](text, regexDat)
						break
					}
				}
				if goToNextLine
					text := this.goToNextLine(text)
			} Until !text
			return text
		}
		
		goToNextLine(str) {
			return subStr(str, RegExMatch(str, "\R+", val) + strLen(val))
		}
		
		addReference(byref text, referenceRegex) {
			this.compileResult.addReference(referenceRegex.2, referenceRegex.1 == "EXTRN")
		}
		
		addDataSegment(byref text, dataSegmentRegex) {
			;get the names of all public references and turn them into a regex
			publicReferences := ""
			for name, reference in this.compileResult.getReferences()
				publicReferences .= "\Q" name . "\E|"
			
			dataSegmentParseData := {("(CONST|_DATA|_BSS)\s+ENDS"):"exitParse"
			,( "(" . RTrim(publicReferences, "|") . ")[^a-zA-Z0-9@_]"):"setDataPointer"
			,("\s*(DB|DD|DQ)\s+([^\n\r]+)"):"addDataToDataSegment"}
			
			this.nullSegment := (dataSegmentRegex.1 = "_BSS")
			
			this.currentSegment := this.compileResult.addSegment(dataSegmentRegex.1)
			test := this.matchParseData(text, dataSegmentParseData)
			text := test
			this.currentSegment := ""
		}
		
		setDataPointer(byref text, regex) {
			this.compileResult.setReferencePosition(regex.1, this.currentSegment, this.currentSegment.getData().getLength())
			return 1
		}
		
		addDataToDataSegment(byref text, regex) {
			dataEntries := strSplit(regex.2, ", ")
			typeSize := {DB:2, DD:8, DQ:16}[regex.1]
			if (this.nullSegment) {
				this.currentSegment.getData().appendHexString(Format("{:0" . (dataEntries.length()*typeSize) . "}", ""))
				return
			}
			for each, entry in dataEntries {
				if (RegexMatch(entry, "0([a-fA-F0-9]+)", data)) {
					this.currentSegment.getData().appendHexString(Format("{:0" . (typeSize) . "s}", data1 ), "BE")
				}
				else if (RegExMatch(entry, "'([^']+)'", data)) {
					for each, character in strSplit(data1) {
						this.currentSegment.getData().appendInteger(ord(character), 2)
					}
				}
			}
		}
		
		addFunctionSegment(byref text, regex) {
			
			;get the names of all public references and if they are undefined add them to a regex
			undefinedReferences := ""
			for name, reference in this.compileResult.getReferences()
				if !reference.getData()
					undefinedReferences .= "\Q" . name . "\E|"
			
			functionSegmentParseData := {("_TEXT\s+ENDS"):"exitParse"
			,("(" . RTrim(undefinedReferences, "|") . ")\s+PROC"):"setFuncData"
			,("\s+[0-9a-fA-F]{5}((?:(?:\s|\R)+(?:[0-9A-Fa-f]{2}))+\s)([^\n\r]+)"):"addFuncData"}
			
			this.currentSegment := this.compileResult.addSegment("_TEXT")
			test := this.matchParseData(text, functionSegmentParseData)
			text := test
			this.currentSegment := ""
		}
		
		setFuncData(byref text, regex) {
			this.compileResult.setReferencePosition(regex.1, this.currentSegment, this.currentSegment.getData().getLength())
			this.compileResult.getReferences()[regex.1].setFunction(true)
		}
		
		addFuncData(byref text, regex) {
			;get all defined references and add them to the reloc regex
			relocRegex := "PTR\s*("
			for name, reference in this.compileResult.getReferences() {
				if (reference.getData())
					relocRegex .= "\Q" name . "\E|"
			}
			relocRegex := RTrim(relocRegex, "|") . ")([^a-zA-Z0-9@_$]|$)"
			
			data := RegExReplace(regex.1, "\s|\R") ;remove the spaces from the hex string
			this.currentSegment.getData().appendHexString(data)
			if (RegexMatch(regex.2, relocRegex, reference)) {
				while (!mod( pos := inStr(data, "00000000", true, A_Index), 2 ))
					if (A_Index > strLen(data)) {
						break
					}
				if (mod(pos, 2)) {
					position := this.currentSegment.getData().getLength() - floor((strLen(data)-pos)/2) - 1
					this.compileResult.addRelocation(reference1, this.currentSegment, position, size)
				}
			}
		}
	}
	
	RunWaitMany(commands) {
		shell := ComObjCreate("WScript.Shell")
		; Open cmd.exe with echoing of commands disabled
		exec := shell.Exec(ComSpec " /Q /K echo off")
		; Send the commands to execute, separated by newline
		exec.StdIn.WriteLine(commands "`nexit")  ; Always exit at the end!
		; Read and return the output of all commands
		return exec.stderr.ReadAll() . "`n" . exec.stdout.ReadAll()
	}
	
}