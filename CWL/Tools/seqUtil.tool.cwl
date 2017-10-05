cwlVersion: v1.0
class: CommandLineTool

label: seqUtil 
doc: |
    Utility tool for various sequence file transformations.

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: seqUtil.log
stderr: seqUtil.error

inputs:
    sequences:
        type: File
        doc: Input sequence file
        format:
            - Formats:fastq
            - Formats:fasta
        inputBinding:
            prefix: --input
    fastq2fasta:
        type: boolean?
        doc: Transform fastq to fasta
        default: false
        inputBinding:
            prefix: --fastq2fasta
    fasta2tab:
        type: boolean?
        doc: Transform fasta to tabbed
        default: false
        inputBinding:
            prefix: --fasta2tab
    sortbyid2tab:
        type: boolean?
        doc: Transform fasta to tabbed, sorted by ID
        default: false
        inputBinding:
            prefix: --sortbyid2tab
    bowtie_truncate:
        type: boolean?
        doc: Return fasta with each sequence truncated to 1024 bps
        default: false
        inputBinding:
            prefix: --bowtie_truncate
    output:
        type: string
        doc: Output sequence file
        inputBinding:
            prefix: --output


baseCommand: [seqUtil]

outputs:
    info:
        type: stdout
    error:
        type: stderr
    file:
        type: File
        outputBinding:
            glob: $(inputs.output)

$namespaces:
  Formats: FileFormats.cv.yaml

