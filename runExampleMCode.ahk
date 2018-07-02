#Include MCodeEx.ahk

if (A_PtrSize == 8)
	Throw exception("The prototype only works on 32 bit AHK")

functions := MCodeEx(FileOpen("output.mcode", "r").read())
Random, current, -0x80000000, 0x7FFFFFFF
DllCall(functions.test, "Int", current+=0x80000000, "Cdecl Int") ;give the test MCode our first value

Loop 8 {
	last := current
	Random, current, -0x80000000, 0x7FFFFFFF
	current+=0x80000000
	returnVal := DllCall(functions.test, "UInt", current, "Cdecl UInt")
	if (ErrorLevel) {
		err := ErrorLevel
		throw exception(clipboard := "Fail:" . err . " `n" . A_LastError)
	} else {
		Msgbox % "what the MCode returns now:`n" . (returnVal) . "`nWhat we input this time:`n" . (current) . "`nWhat we put into it the last time:`n" . (last) . "`n"
	}
}
Msgbox % "result: MCode-EX is able to store data in variables`nThis is pretty impressive since normal MCode isn't capable of doing that"
Msgbox % "MCode EX solves several problems that arise when dealing with MCode and makes the technique more useful"