class VSCompiler {
	
	static compileBatString := "CALL ""{1:s}""`r`ncl {2:s} /Ox /FAcu /TC /c /arch:SSE2"
	
	setInputFile(file) {
		this.inputFile := file
	}
	
	compile(bitness := "32") {
		compileString := Format(this.compileBatString, this.getCompilerLocation(), this.inputFile)
		Msgbox % compileString
		Msgbox % A_LineFile "/../../tmp/compile.bat"
		fileOpen(A_LineFile "/../../tmp/compile.bat", "w").write(compileString)
		RunWait % A_LineFile "/../../tmp/compile.bat"
	}
	
	getCompilerLocation() {
		return "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvarsx86_amd64.bat"
	}
	
}