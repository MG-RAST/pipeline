cwlVersion: v1.0
class: CommandLineTool

label: CD-HIT
doc: |
    cluster protein sequences
    use max available cpus and memory
    >cdhit -n 5 -d 0 -T 0 -M 0 -c 0.9 -i <input> -o <output>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: cdhit.log
stderr: cdhit.error

inputs:
    input:
        type: File
        doc: Input fasta format file
        format:
            - Formats:fasta
        inputBinding:
            prefix: -i
    
    identity:
        type: float?
        doc: Percent identity threshold, default 0.9
        default: 0.9
        inputBinding:
            prefix: -c
    
    word:
        type: int?
        doc: Word length, default 5
        default: 5
        inputBinding:
            prefix: -n
    
    outName:
        type: string
        doc: Output name
        inputBinding:
            prefix: -o


baseCommand: [cdhit]

arguments:
    - prefix: -M
      valueFrom: "0"
    - prefix: -T
      valueFrom: "0"
    - prefix: -d
      valueFrom: "0"

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    outSeq:
        type: File
        doc: Output fasta format file
        outputBinding: 
            glob: $(inputs.outName)
    outClstr:
        type: File
        doc: Output cluster mapping file
        outputBinding: 
            glob: $(inputs.outName).clstr

$namespaces:
    Formats: FileFormats.cv.yaml

