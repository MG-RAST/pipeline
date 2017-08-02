cwlVersion: v1.0
class: CommandLineTool

label: source stats file reformat
doc: |
    re-formats source tsv profile into json stats summary
    >format_source_stats.pl --input <input> --output <output>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: format_source_stats.log
stderr: format_source_stats.error

inputs:
    input:
        type: File
        doc: Input source profile file
        format:
            - Formats:tsv
        inputBinding:
            prefix: --input
    
    outName:
        type: string
        doc: Output source stats file
        inputBinding:
            prefix: --output


baseCommand: [format_source_stats.pl]

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    output:
        type: File
        doc: Output json format file
        outputBinding: 
            glob: $(inputs.outName)

$namespaces:
    Formats: FileFormats.cv.yaml

