class MCodeExPackage {
	
	buildPackage(compiler) {
		
		linkerData32 := this.compile(compiler, "32")
		linkerData64 := this.compile(compiler, "64")
		
		packageBinary := new Binary()
		
		packageBinary.appendInteger(linkerData32.functions.count(), 2)
		;this just adds the functions from the 32 bit compilation/linking
		;however I assume they remain the same in both 64 and 32 linking
		
		for name, function in linkerData32.functions {
			for each, character in strSplit(name) {
				;write the name of the current function to the binary
				packageBinary.appendInteger(Ord(character), 1) 
			}
			;encoding used: UTF-8 however it is limited to very few characters
			;add the null terminator
			packageBinary.appendInteger(0, 1) 
			;get the position relative to the segment the current function is contained in
			position32 := function.getData()
			position64 := linkerData64.functions[name].getData()
			;take in the offsets of that segment and get the total position
			packageBinary.appendInteger(linkerData32.offsets[position32.segment] + position32.position, 2)
			;here would be the 64 bit offset but I leave that empty for now
			packageBinary.appendInteger(linkerData64.offsets[position64.segment] + position64.position, 2)
		}
		;the count for external references - for now this is just a reserved field
		packageBinary.appendInteger(0, 2)
		;the offset of the 64 bit MCode data - relative to the beginning of the entire MCode data
		;0 means no 64 bit data - 0xFFFF means no 32 bit data
		packageBinary.appendInteger(packageBinary.getSize()+4+linkerData32.relocations.length()*2+linkerData32.binary.getSize(), 2)
		
		;from here on we will add the data specific to the 32 bit MCode:
		;relocations:
		;first the relocation count
		packageBinary.appendInteger(linkerData32.relocations.length(), 2)
		for each, relocation in linkerData32.relocations {
			;then their positions in the following data
			packageBinary.appendInteger(relocation, 2)
		}
		
		;add the 32 bit MCode
		packageBinary.appendBinaryObject(linkerData32.binary)
		
		;from here on we will add the data specific to the 64 bit MCode:
		;relocations:
		;first the relocation count
		packageBinary.appendInteger(linkerData64.relocations.length(), 2)
		for each, relocation in linkerData64.relocations {
			;then their positions in the following data
			packageBinary.appendInteger(relocation, 2)
		}
		
		;add the 64 bit MCode
		packageBinary.appendBinaryObject(linkerData64.binary)
		
		;and just return the binary as hex
		return packageBinary.getHexString()
	}
	
	compile(compiler, bitness) {
		result := compiler.compile(bitness)
		linkerData := this.getRelevantSegments(result)
		this.combineSegments(linkerData)
		this.resolveRelocations(linkerData)
		return linkerData
	}
	
	getRelevantSegments(result) {
		addedSegments	:= []
		addedFunctions	:= {}
		linkerData := {segments:addedSegments, functions:addedFunctions}
		for each, function in result.getFunctions() {
			this.addSegment(addedSegments, function.getData().segment)
			addedFunctions[LTrim(function.getName(), "_")] := function
		}
		return linkerData
	}
	
	addSegment(addedSegments, segment) {
		if (!addedSegments[segment]) {
			addedSegments[segment] := segment
			for each, relocation in segment.getRelocations() {
				this.addSegment(addedSegments, relocation.reference.getData().segment)
			}
		}
	}
	
	combineSegments(linkerData) {
		output := new Binary()
		segmentOffsets := {}
		for each, segment in linkerData.segments {
			segmentOffsets[segment] := output.getSize()
			output.appendBinaryObject(segment.getData())
		}
		linkerData.binary	:= output
		linkerData.offsets	:= segmentOffsets
	}
	
	resolveRelocations(linkerData) {
		relocations := []
		for segment, offset in linkerData.offsets {
			for each, relocation in segment.getRelocations() {
				referenceData := relocation.reference.getData()
				linkerData.binary.numPut(referenceData.position + linkerData.offsets[referenceData.segment], relocation.position + offset, 4)
				relocations.push(relocation.position + offset)
			}
		}
		linkerData.relocations := relocations
	}
	
}