cwlVersion: v1.0
class: CommandLineTool

label: GNU sort
doc: sort text file base on given field(s)

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: sort.log
stderr: sort.error

inputs:
    input:
        type: File[]
        doc: Files to sort
        inputBinding:
            position: 2
    
    key:
        type:
            type: array
            items: string 
            inputBinding:
                prefix: -k
        doc: start a key at POS1, end it at POS2 (origin 1)
        inputBinding:
            position: 1
    
    field:
        type: string?
        doc: use SEP instead of non-blank to blank transition, default is tab
        inputBinding:
            prefix: -t
            valueFrom: $("\u0009")
    
    merge:
        type: boolean?
        doc: merge only, the input files are assumed to be pre-sorted
        inputBinding:
            prefix: -m
    
    outName:
        type: string
        doc: write result to FILE instead of standard output
        inputBinding:
            prefix: -o


baseCommand: [sort]

arguments:
    - prefix: -T
      valueFrom: $(runtime.tmpdir)
    - prefix: -S
      valueFrom: $(runtime.ram)M

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    output:
        type: File
        doc: The sorted file
        outputBinding: 
            glob: $(inputs.outName)

