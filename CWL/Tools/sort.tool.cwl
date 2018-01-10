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
        type: File
        doc: File to sort
        format:
            - Formats:tsv
        inputBinding:
            position: 1
    
    key:
        type: string 
        inputBinding:
            prefix: -k
        doc: |
            -k, --key=POS1[,POS2]
            start a key at POS1, end it at POS2 (origin 1)
    
    field:
        type: string?
        doc: |
            -t, --field-separator=SEP
            use SEP instead of non-blank to blank transition
            default is tab
        inputBinding:
            prefix: -t
            valueFrom: $("\u0009")
    
    outName:
        type: string
        doc: |
            -o, --output=FILE
            write result to FILE instead of standard output
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
        type: File?
        doc: The sorted file
        outputBinding: 
            glob: $(inputs.outName)

$namespaces:
    Formats: FileFormats.cv.yaml

