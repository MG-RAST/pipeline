cwlVersion: v1.0
class: CommandLineTool

label: fastq-mcf
doc: |
    fastq quality trimmer
    >fastq-mcf 'n/a' <input> -S -k 0 -l <minLength> --max-ns <maxLqb> -q <minQual> -w <window> -o <outName>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: fastq-mcf.log
stderr: fastq-mcf.error

inputs:
    input:
        type: File
        doc: Input fastq sequence file
        format:
            - Formats:fastq
        inputBinding:
            position: 1
    
    minQual:
        type: int?
        doc: Quality threshold causing base removal, default 15
        default: 15
        inputBinding:
            prefix: -q
    
    maxLqb:
        type: int?
        doc: Maxmium N-calls in a read, default 5
        default: 5
        inputBinding:
            prefix: --max-ns
    
    window:
        type: int?
        doc: Window-size for quality trimming, default 10
        default: 10
        inputBinding:
            prefix: -w
    
    minLength:
        type: int?
        doc: Minimum remaining sequence length, default 50
        default: 50
        inputBinding:
            prefix: -l
    
    outName:
        type: string
        doc: Output name
        inputBinding:
            prefix: -o


baseCommand: [fastq-mcf]

arguments:
    - position: 0
      valueFrom: 'n/a'
    - valueFrom: -S
    - prefix: -k
      valueFrom: "0"

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    outTrim:
        type: File
        doc: Output trimmed fastq sequences
        outputBinding: 
            glob: $(inputs.outName)
    outSkip:
        type: File
        doc: Output skipped fastq sequences
        outputBinding: 
            glob: $(inputs.outName).skip

$namespaces:
    Formats: FileFormats.cv.yaml

