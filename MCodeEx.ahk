MCodeEx(mcodeString) {
	
	c := (A_PtrSize-4)/2 
	if RegExMatch(mcodeString, "^[0-9A-Fa-f]+$") {
		e := 4
	}
	if (!DllCall("crypt32\CryptStringToBinary", "str", mcodeString, "uint", 0, "uint", e, "ptr", 0, "uint*", s, "ptr", 0, "ptr", 0))
		Throw Exception("Failed CryptStringToBinary: ErrorLevel:" . ErrorLevel . " A_LastError" . A_LastError)
	p := DllCall("VirtualAlloc", "Ptr", 0, "UInt", s, "UInt", 0x3000, "UInt", 0x40)
	DllCall("VirtualLock", "Ptr", p, "UInt", s)
	
	if (!DllCall("crypt32\CryptStringToBinary", "str", mcodeString, "uint", 0, "uint", e, "ptr", p, "uint*", s, "ptr", 0, "ptr", 0)) {
		DllCall("GlobalFree", "ptr", p)
		Throw Exception("Failed CryptStringToBinary: ErrorLevel:" . ErrorLevel . " A_LastError" . A_LastError)
	}
	fnCount := NumGet((p+0), 0, "UShort")
	offset  := 2
	functions := {}
	Loop %fnCount% {
		fnName := StrGet((p+offset), 40, "Utf-8")
		offset += StrLen(fnName)+1
		fnOffset := NumGet((p+0), offset + c, "UShort" )
		offset += 4
		functions[fnName] := fnOffset
	}
	
	extCount := NumGet((p+0), offset, "UShort") ;reserved
	if extCount {
		Throw Exception("Externals are not supported yet")
	}
	offset += 2
	
	if (c) {
		offset := NumGet((p+0), offset, "UShort")
	} else {
		offset += 2
	}
	
	relocCount := NumGet((p+0), offset, "UShort")
	offset += 2
	relocations := []
	Loop %relocCount% {
		relocations.push(NumGet((p+0), offset, "UShort"))
		offset += 2
	}
	
	for each, reloc in relocations {
		relocVal := numGet((p+0), offset + reloc, "UPtr" )
		numPut( p+relocVal+offset, (p+0), offset + reloc, "UPtr")
	}
	
	
	for each, function in functions {
		functions[each] += offset + p
	}
	
	DllCall("FlushInstructionCache", "Ptr", DllCall("GetCurrentProcess"), "Ptr", p, "UInt", s)
	
	functions[""]   := p
	functions["`t"] := s
	return functions
}