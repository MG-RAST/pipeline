cwlVersion: v1.0
class: CommandLineTool

label: uncluster sims
doc: |
    expand out similarity file (blast m8) by turning each cluster seed hit into a hit per cluster member
    >uncluster_sims.py <input> <outName> --cfile <cluster> --position <position>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: uncluster_sims.log
stderr: uncluster_sims.error

inputs:
    input:
        type: File
        doc: Input similarity blast-m8 file
        format:
            - Formats:tsv
        inputBinding:
            position: 1

    outName:
        type: string
        doc: Output expanded similarity
        inputBinding:
            position: 2

    cluster:
        type: File
        doc: Input cluster mapping file
        inputBinding:
            prefix: --cfile

    position:
        type: int?
        doc: Column position of query in sims file, default is 1
        default: 1
        inputBinding:
            prefix: --position


baseCommand: [uncluster_sims.py]

arguments:
    - valueFrom: --verbose
    - prefix: --db
      valueFrom: $(runtime.tmpdir)

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    output:
        type: File
        doc: Output expanded similarity file
        outputBinding: 
            glob: $(inputs.outName)

$namespaces:
    Types: ProfileTypes.cv.yaml

