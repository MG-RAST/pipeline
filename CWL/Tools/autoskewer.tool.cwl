cwlVersion: v1.0
class: CommandLineTool

label: autoskewer
doc: |
    detect and trim adapter sequences from reads
    >autoskewer.py -t <runtime.tmpdir> -i <input> -o <outName> -l <outLog>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03
    
requirements:
    InlineJavascriptRequirement: {}

stdout: autoskewer.log
stderr: autoskewer.error

inputs:
    input:
        type: File
        doc: Input sequence file
        format:
            - Formats:fastq
            - Formats:fasta
        inputBinding:
            prefix: -i
    
    outName:
        type: string
        doc: Output trimmed sequences
        inputBinding:
            prefix: -o
    
    outLog:
        type: string?
        doc: Optional output trimmed log
        inputBinding:
            prefix: -l

baseCommand: autoskewer.py

arguments:
    - prefix: -t
      valueFrom: $(runtime.tmpdir)

outputs:
    info:
        type: stdout
    error: 
        type: stderr
    outTrim:
        type: File
        doc: Output trimmed sequences
        outputBinding: 
            glob: $(inputs.outName)
    trimLog:
        type: File?
        doc: Optional output trimmed log file
        outputBinding:
            glob: $(inputs.outLog)

$namespaces:
    Formats: FileFormats.cv.yaml

