cwlVersion: v1.0
class: CommandLineTool

label: CD-HIT-est
doc: |
    cluster nucleotide sequences
    >cdhit-est -n $word -d 0 -T 0 -M 0 -c $pid -i $fasta -o $output

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: cdhit-est.log
stderr: cdhit-est.error

inputs:
    sequence:
        type: File
        doc: Input fasta format file
        format:
            - Formats:fasta
        inputBinding:
            prefix: -i
    
    identity:
        type: float?
        doc: Percent identity threshold, default 0.97
        default: 0.97
        inputBinding:
            prefix: -c
    
    word:
        type: int?
        doc: Word length, default 9
        default: 9
        inputBinding:
            prefix: -n
    
    output:
        type: string
        doc: Output name
        inputBinding:
            prefix: -o


baseCommand: [cdhit-est]

arguments:
    - prefix: -M
      valueFrom: $(runtime.ram)
    - prefix: -T
      valueFrom: $(runtime.cores)
    - prefix: -d
      valueFrom: 0

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    outSeq:
        type: File
        doc: Output fasta format file
        outputBinding: 
            glob: $(inputs.output)
    outClstr:
        type: File
        doc: Output cluster mapping file
        outputBinding: 
            glob: $(inputs.output).clstr

$namespaces:
    Formats: FileFormats.cv.yaml

