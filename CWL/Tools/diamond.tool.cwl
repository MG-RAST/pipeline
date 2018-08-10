cwlVersion: v1.0
class: CommandLineTool

label: diamond
doc: |
    multi-threaded fast sequence search command line tool, protein only
    >diamond -t <tempdir> -b <blocksize> -d <database> -q <query> -o <output>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.04

requirements:
    InlineJavascriptRequirement: {}

stdout: diamond.log
stderr: diamond.error

inputs:
    database:
        type: File
        doc: Database fasta format file
        format:
            - Formats:fasta
        inputBinding:
            prefix: -d
    
    query:
        type: File
        doc: Query fasta format file
        format:
            - Formats:fasta
        inputBinding:
            prefix: -q
    
    outName:
        type: string
        doc: Output name
        inputBinding:
            prefix: -o
    
    blockSize:
        type: float?
        doc: Control memory useage, this number x 6 in GB
        default: 10.0
        inputBinding:
          prefix: -b
    
    tempDir:
        type: string?
        doc: Temp dir for files, use memory for default
        default: /dev/shm
        inputBinding:
          prefix: -t


baseCommand: [diamond]

arguments:
    command:
        position: 0
        valueFrom: blastp

outputs:
    info:
        type: stdout
    error: 
        type: stderr
    output:
        type: File
        doc: Output tab separated similarity file
        outputBinding: 
            glob: $(inputs.outName)

$namespaces:
    Formats: FileFormats.cv.yaml

