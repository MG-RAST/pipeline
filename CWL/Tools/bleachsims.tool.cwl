cwlVersion: v1.0
class: CommandLineTool

label: bleachsims
doc: |
    filter similarity file by E-value and number of hits
    >bleachsims -s <input> -o <output> -m 20 -r 0 -c 3

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: bleachsims.log
stderr: bleachsims.error

inputs:
    input:
        type: File
        doc: Input similarity blast-m8 file
        format:
            - Formats:tsv
        inputBinding:
            prefix: -s
    
    min:
        type: int?
        doc: Minimum # of results per query, default 20
        default: 20
        inputBinding:
            prefix: -m
    
    range:
        type: int?
        doc: Best evalue plus this exponent that will be returned, default 0 (no range)
        default: 0
        inputBinding:
            prefix: -r
    
    cutoff:
        type: int?
        doc: Remove all evalues with an exponent lower than cutoff, default 3
        default: 3
        inputBinding:
            prefix: -c
    
    outName:
        type: string
        doc: Output name
        inputBinding:
            prefix: -o


baseCommand: [bleachsims]

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    output:
        type: File
        doc: Output filtered similarity blast-m8 file
        outputBinding: 
            glob: $(inputs.outName)

$namespaces:
    Formats: FileFormats.cv.yaml

