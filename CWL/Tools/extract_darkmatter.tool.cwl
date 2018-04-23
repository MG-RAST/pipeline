cwlVersion: v1.0
class: CommandLineTool

label: extract darkmatter
doc: |
    retrieve predicted proteins that have no similarity hits
    >extract_darkmatter.py -i <input> -s <sim 1> -s <sim 2> -m <clust map 1> -m <clust map 2> -o <outName>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: extract_darkmatter.log
stderr: extract_darkmatter.error

inputs:
    geneSeq:
        type: File
        doc: Input gene sequence file
        format:
            - Formats:fasta
        inputBinding:
            prefix: -i

    simHit:
        type:
            type: array
            items: File
            inputBinding:
                prefix: -s
        doc: Input similarity hit files

    clustMap:
        type:
            type: array
            items: File
            inputBinding:
                prefix: -m
        doc: Input cluster mapping files

    outName:
        type: string
        doc: Output darkmatter sequence
        inputBinding:
            prefix: -o


baseCommand: [extract_darkmatter.py]

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    output:
        type: File
        doc: Output darkmatter sequence file
        outputBinding: 
            glob: $(inputs.outName)

$namespaces:
    Types: ProfileTypes.cv.yaml

