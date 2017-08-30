cwlVersion: v1.0
class: CommandLineTool

label: cluster file reformat
doc: |
    re-formats cd-hit .clstr file into mg-rast .mapping file
    >format_cluster.pl --input <input> --output <output>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: format_cluster.log
stderr: format_cluster.error

inputs:
    input:
        type: File
        doc: Input .clstr format file
        inputBinding:
            prefix: --input
    
    outName:
        type: string
        doc: Output .mapping format file
        inputBinding:
            prefix: --output


baseCommand: [format_cluster.pl]

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    output:
        type: File
        doc: Output .mapping format file
        outputBinding: 
            glob: $(inputs.outName)

$namespaces:
    Formats: FileFormats.cv.yaml

