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
        inputBinding:
            prefix: --fastq2fasta
    fasta2tab:
        type: boolean?
        doc: Transform fasta to tabbed
        inputBinding:
            prefix: --fasta2tab
    sortbyid:
        type: boolean?
        doc: Sort fasta file by ID
        inputBinding:
            prefix: --sortbyid
    sortbyid2tab:
        type: boolean?
        doc: Transform fasta to tabbed, sorted by ID
        inputBinding:
            prefix: --sortbyid2tab
    sortbyid2id:
        type: boolean?
        doc: Transform fasta to ID list, sorted by ID
        inputBinding:
            prefix: --sortbyid2id
    bowtieTruncate:
        type: boolean?
        doc: Return fasta with each sequence truncated to 1024 bps
        inputBinding:
            prefix: --bowtie_truncate
    subsetSeqs:
        type: boolean?
        doc: Return fasta with each sequence truncated to 1024 bps
        inputBinding:
            prefix: --subset_seqs
    subsetList:
        type: File?
        doc: List of sequences to subset input by, required with subsetSeqs option
        inputBinding:
            prefix: --list
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

