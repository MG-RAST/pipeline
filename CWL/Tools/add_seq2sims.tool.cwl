cwlVersion: v1.0
class: CommandLineTool

label: uncluster sims
doc: |
    append feature sequence to each hit line of similarity file
    >add_seq2sims --seq_file --in_sim 

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: add_seq2sims.log
stderr: add_seq2sims.error

inputs:
    sequences:
        type: File
        doc: Input tabbed sequence file
        format:
            - Formats:tsv
        inputBinding:
            prefix: --seq_file

    similarity:
        type: File
        doc: Input similarity file
        format:
            - Formats:tsv
        inputBinding:
            prefix: --in_sim

    outName:
        type: string
        doc: Output merged sims and seq
        inputBinding:
            prefix: --out_sim


baseCommand: [add_seq2sims]

arguments:
    - prefix: --verbose

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    output:
        type: File
        doc: Output merged sims and seq file
        outputBinding: 
            glob: $(inputs.outName)

$namespaces:
    Types: ProfileTypes.cv.yaml

