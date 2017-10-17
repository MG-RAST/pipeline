cwlVersion: v1.0
class: CommandLineTool

label: superBLAT
doc: |
    multi-threaded fast sequence search command line tool, protein only
    >superblat -fastMap -prot -out blast8 <database> <query> <output>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: superblat.log
stderr: superblat.error

inputs:
    database:
        type: File
        doc: Database fasta format file
        format:
            - Formats:fasta
        inputBinding:
            position: 1
    
    query:
        type: File
        doc: Query fasta format file
        format:
            - Formats:fasta
        inputBinding:
            position: 2
    
    outName:
        type: string
        doc: Output name
        inputBinding:
            position: 3
    
    fastMap:
        type: boolean?
        doc: Run for fast DNA/DNA remapping - not allowing introns
        inputBinding:
          prefix: -fastMap


baseCommand: [superblat]

arguments:
    - -prot
    - -out=blast8

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

