cwlVersion: v1.0
class: CommandLineTool

label: GNU cat
doc: Concatenate FILE(s) to standard output

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: $(inputs.outName)
stderr: cat.error

inputs:
    files:
        type:
            type: array
            items: File
        doc: List of files to concatenate
        inputBinding:
            position: 1
    
    outName:
        type: string


baseCommand: [cat]

outputs:
    error: 
        type: stderr
    output:
        type: File
        doc: Concatenated file
        outputBinding: 
            glob: $(inputs.outName)

