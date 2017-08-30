cwlVersion: v1.0
class: CommandLineTool

label: filter features
doc: |
    remove predicted genes that have overlap with identified rRNAs
    >filter_feature.pl --seq <sequences> --sim <similarity> --clust <cluster> --output <output> --overlap <overlap> --memory <memory in MB> --tmp_dir <temp directory>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: filter_feature.log
stderr: filter_feature.error

inputs:
    sequences:
        type: File
        doc: Input tabbed protein sequence file
        format:
            - Formats:tsv
        inputBinding:
            prefix: --seq

    similarity:
        type: File
        doc: Input RNA similarity file
        format:
            - Formats:tsv
        inputBinding:
            prefix: --sim

    cluster:
        type: File
        doc: Input RNA cluster mapping file
        inputBinding:
            prefix: --clust

    overlap:
        type: int?
        doc: Overlap threshold in bp to accept, default 10
        default: 10
        inputBinding:
            prefix: --overlap

    outName:
        type: string
        doc: Output filtered protein fasta
        inputBinding:
            prefix: --output


baseCommand: [filter_feature.pl]

arguments:
    - prefix: --memory
      valueFrom: $(runtime.ram)
    - prefix: --tmpdir
      valueFrom: $(runtime.tmpdir)

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    output:
        type: File
        doc: Output filtered protein fasta file
        outputBinding: 
            glob: $(inputs.outName)

$namespaces:
    Types: ProfileTypes.cv.yaml

