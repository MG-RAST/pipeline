cwlVersion: v1.0
class: CommandLineTool

label: rna features
doc: |
    identify rRNAs features from given rRNA fasta and blast aligned files
    >rna_feature.pl --seq <sequence> --sim <aligned> --ident 75 --output <output>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: rna_feature.log
stderr: rna_feature.error

inputs:
    sequence:
        type: File
        doc: Tab separated sequence file
        format:
            - Formats:tsv
        inputBinding:
            prefix: --seq
    
    aligned:
        type: File
        doc: Tab separated similarity file
        format:
            - Formats:tsv
        inputBinding:
            prefix: --sim
    
    identity:
        type: int?
        doc: Percent identity threshold, default 75
        default: 75
        inputBinding:
            prefix: --ident
    
    outName:
        type: string
        doc: Output fasta format file
        inputBinding:
            prefix: --output


baseCommand: [rna_feature.pl]

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    output:
        type: File
        doc: Output fasta format file
        outputBinding: 
            glob: $(inputs.outName)

$namespaces:
    Formats: FileFormats.cv.yaml

