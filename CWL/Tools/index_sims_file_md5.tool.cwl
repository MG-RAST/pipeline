cwlVersion: v1.0
class: CommandLineTool

label: index sims by md5
doc: |
    index m8 format blast file by 2nd column (sorted required)
    return: value, seek, length for each record
    >index_sims_file_md5 --in_file <input> --out_file <outName> --md5_num <number>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: index_sims_file_md5.log
stderr: index_sims_file_md5.error

inputs:
    input:
        type: File
        doc: Input similarity blast-m8 file
        format:
            - Formats:tsv
        inputBinding:
            prefix: --in_file

    number:
        type: int?
        doc: Number of chunks to load in memory at once before processing, default is 5000
        default: 5000
        inputBinding:
            prefix: --md5_num

    outName:
        type: string
        doc: Output index
        inputBinding:
            prefix: --out_file


baseCommand: [index_sims_file_md5]

arguments:
    - valueFrom: --verbose

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    output:
        type: File
        doc: Output index file
        outputBinding: 
            glob: $(inputs.outName)

$namespaces:
    Types: ProfileTypes.cv.yaml

