# MCode-Ex Prototype:
The first showcase of MCodes-Ex main new mechanism
This is an example Prototype which combines a simple compiler with a simple MCodeFunction that is able to read the compiled code.

## Using this prototype:
1. You compile exampleMCode.c with compile.bat -> this creates exampleMCode.cod and exampleMCode.obj
2. You launch extractMCode.ahk which will read exampleMCode.cod and create the MCode based on it -> it will output to output.mcode
3. You launch runExampleMCode.ahk it will read the output.mcode and create executeable code using it. Afterwards it will use the created code in a examplified DllCal to demonstrate it's uses

## Making this prototype work on your PC:
All the code is written for AHK v1.1 32 Bit Version (String Encoding doesn't matter) please use this version to run the scripts.
compile.bat contains a path to a bat file which is needed to make visual studio compile - if you want to run this prototype on your PC you need to adjust that path

## Known Bugs or limitations:
The BSS sections doesn't get parsed at all
When adding data it adds all data that Visual Studio mentions - not all mentioned data is actually needed though