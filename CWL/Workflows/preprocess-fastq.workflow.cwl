cwlVersion: v1.0
class: Workflow

label: preprocess fastq
doc: |
    Remove and trim low quality reads from fastq files. 
    Return fasta files with reads passed and reads removed.

requirements:
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
    - class: ScatterFeatureRequirement
    - class: MultipleInputFeatureRequirement

inputs:
    jobid: string
    sequences: File
    minQual:
        type: int
        default: 15
    maxLqb:
        type: int
        default: 5
    minLength:
        type: int
        default: 30

outputs:
    passed:
        type: File
        outputSource: passed2fasta/file
    removed:
        type: File
        outputSource: removed2fasta/file  

steps:
    filter:    
        run: ../Tools/fastq-mcf.tool.cwl
        in:
            input: sequences
            minQual: minQual
            maxLqb: maxLqb
            minLength: minLength
            outPassed:
                source: jobid
                valueFrom: $(self).100.preprocess.passed
            outRemoved:
                source: jobid
                valueFrom: $(self).100.preprocess.removed
        out: [passed, removed]

    passed2fasta:
        run: ../Tools/seqUtil.tool.cwl
        in:
            sequences: filter/passed
            fastq2fasta: 
                default: true
            output:
                source: filter/passed
                valueFrom: $(self).fna
        out: [file]

    removed2fasta:
        run: ../Tools/seqUtil.tool.cwl
        in:
            sequences: filter/removed
            fastq2fasta: 
                default: true
            output:
                source: filter/removed
                valueFrom: $(self).fna
        out: [file]
