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
    simHit:
        type:
            type: array
            items: File
            inputBinding:
                prefix: -i
        doc: Input similarity hit files

    clustMap:
        type:
            type: array
            items: File
            inputBinding:
                prefix: -c
        doc: Input cluster mapping files

    position:
        type: int?
        doc: Column position of query in sims file, default is 1
        default: 1
        inputBinding:
            prefix: --position

    outName:
        type: string
        doc: Output unclustered similarity
        inputBinding:
            prefix: -o


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
        doc: Output unclustered similarity file
        outputBinding: 
            glob: $(inputs.outName)

$namespaces:
    Types: ProfileTypes.cv.yaml

