class MCodeExPackage {
	
	buildPackage(compiler) {
		packageBinary := new Binary()
		linkerData1 := this.compile(compiler)
		packageBinary.appendInteger(linkerData1.getFunctions().length(), 2)
		for each, function in linkerData1.getFunctions() {
			
		}
	}
	
	compile(compiler) {
		result := compiler.compile()
		linkerData := this.getRelevantSegments(result)
		this.combineSegments(linkerData)
		this.resolveRelocations(linkerData)
		return linkerData
	}
	
	getRelevantSegments(result) {
		addedSegments	:= []
		addedFunctions	:= []
		linkerData := {segments:addedSegments, functions:addedFunctions}
		for each, function in result.getFunctions() {
			this.addSegment(addedSegments, function.getData().segment)
			addedFunctions.push([LTrim(function.getName(), "_")])
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
			for each, 
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