cwlVersion: v1.0
class: CommandLineTool

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: load_cass.stats
stderr: load_cass.error

inputs:
    mgid:
        type: string
        doc: metagenome identifier
        inputBinding:
            prefix: --mgid

    file:
        type: File
        doc: abundance file
        inputBinding:
            prefix: --file

    type:
        type: string
        doc: abundance type:\ md5 or lca
        inputBinding:
            prefix: --type

    annVer:
        type: int?
        doc: m5nr annotation version number
        default: 1
        inputBinding:
            prefix: --ann_ver

    apiUrl:
        type: string?
        doc: MG-RAST API url
        default: http://api.metagenomics.anl.gov
        inputBinding:
            prefix: --api_url

baseCommand: [load_cass.pl]

arguments:
    - --verbose

outputs:
    info:
        type: stdout
    error: 
        type: stderr

