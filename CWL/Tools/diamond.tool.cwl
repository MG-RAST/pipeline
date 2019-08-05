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
        inputBinding:
            prefix: -d
    
    query:
        type: File
        doc: Query fasta format file
        inputBinding:
            prefix: -q
    
    outName:
        type: string
        doc: Output name
        inputBinding:
            prefix: -o
    
    maxTarget:
        type: int?
        doc: Maximum target sequences per query to keep
        default: 20
        inputBinding:
          prefix: -k
    
    evalue:
        type: float?
        doc: Maximum expected value to report
        default: 0.001
        inputBinding:
          prefix: -e
    
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
    - valueFrom: blastp
      position: 0

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

