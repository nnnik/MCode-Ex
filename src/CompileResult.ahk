class CompileResult {
	__New() {
		this.segments		:= []
		this.references	:= {}
	}
	
	__Delete() {
		for each, segment in this.segments {
			segment._delete()
		}
		for each, reference in this.references {
			reference._delete()
		}
	}
	
	getReferences() {
		return this.references
	}
	
	getSegements() {
		return this.segments
	} 
	
	addSegment(type, data:="", containedReferences := "", relocations := "") {
		segmentClass := this.Segment
		segment := new segmentClass(this, type, data, containedReferences, relocations)
		this.segments.push(segment)
		return segment
	}
	
	addReference(name, extern := false,  function := false) {
		if this.references.hasKey(name)
			throw exception("duplicate reference error: " . name, -1)
		referenceClass := this.Reference
		reference := new referenceClass(name, extern, function)
		this.references[name] := reference
		return reference
	}
	
	setReferencePosition(reference, segment, position) {
		if !isObject(reference){
			if !this.references.hasKey(reference)
				throw exception("invalid reference", -1)
			else
				reference := this.references[reference]
		}
		reference.setData(segment, position)
		segment.addContainedReference(reference, position)
	}
	
	addRelocation(reference, segment, position) {
		if !isObject(reference){
			if !this.references.hasKey(reference)
				throw exception("invalid reference", -1)
			else
				reference := this.references[reference]
		}
		reference.addMention(segment, position)
		segment.addRelocation(reference, position)
	}
	
	class Segment {
		static types := {_TEXT:1, CONST:1, _DATA:1}
		
		__New(parent, type, data := "", containedReferences := "", relocations := "") {
			if (!type || !this.types[type]) {
				throw exception("unsupported segment type : """ . type . """")
			}
			if (!data) {
				binaryClass := parent.Binary
				data := new binaryClass()
			}
			if (!containedReferences ) {
				containedReferences  := {}
			}
			if (!relocations) {
				relocations := []
			}
			this.type					:= type
			this.data					:= data
			this.containedReferences 	:= containedReferences 
			this.relocations			:= relocations
		}
		
		getData() {
			return this.data
		}
		
		getContainedReferences() {
			return this.containedReferences
		}
		
		getRelocations() {
			return this.relocations
		}
		
		addContainedReference(reference, position) {
			this.containedReferences[reference.getName()] := reference
		}
		
		addRelocation(reference, position) {
			this.relocations.push({reference:reference, position:position})
		}
		
		_delete() {
			this.relocations := ""
			this.containedReferences := ""
		}
	}
	
	class Binary {
		__New(endianness := "LE") {
			this.endianness	:= endianness
			this.size 		:= 0
			this.hexString		:= ""
		}
		
		getSize() {
			return this.size
		}
		
		getLength() {
			return this.size
		}
		
		getHexString() {
			return this.hexString
		}
		
		getEndianness() {
			return this.endiannes
		}
		
		appendHexString(hex, endianness := "LE") {
			hex := regexReplace(hex, "\s")
			if (!RegexMatch(hex, "^([a-fA-F0-9]{2})+$"))
				throw exception("invalid hex")
			if (endianness != this.endianness) {
				hex := this.invertHex(hex)
			}
			this.hexString	.= hex
			this.size		+= round(strLen(hex)/2)
		}
		
		appendInteger(integer, byteSize, endianness := "BE") {
			if (log(integer)/log(2) > byteSize) {
				throw exception("provided integer is greater than the maximum number that can be encoded with")
			}
			this.appendHexString(Format( "{:0" . (size*2) . "x}", integer ), endianness)
		}
		
		appendBinaryObject(bin) {
			if (bin.__class != this.__class)
				throw exception("incompatible binary formats", -1)
			if (this.getEndianness() != bin.getEndianness()) {
				throw exception("incompatible endianness", -1)
			}
			this.appendHexString(bin.getHexString())
		}
		
		invertHex(byref hex) {
			outHex := ""
			len := strLen(hex)/2
			Loop % len {
				outHex .= subStr(hex, (len-A_Index)*2+1, 2)
			}
			return outHex
		}
	}
	
	class Reference {
		__New(name, extern := false,  function := false) {
			this.name			:= name
			this.mentions		:= []
			this.extern		:= extern
			this.function		:= function
		}
		
		getName() {
			return this.name
		}
		
		getData() {
			if this.hasKey("segment")
				return {segment:this.segment, position:this.position}
		}
		
		setData(segment, position) {
			this.segment  := segment
			this.position := position
		}
		
		addMention(segment, position) {
			this.mentions.push({segment:segment, position:position})
		}
		
		setFunction(functionFlag := true) {
			this.function := functionFlag
		}
		
		_Delete() {
			this.segment	:= ""
			this.mentions	:= ""
		}
	}
	
}