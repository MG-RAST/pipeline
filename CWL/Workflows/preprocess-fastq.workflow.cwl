cwlVersion: v1.0
class: Workflow

label: preprocess-fastq
doc: |
    Remove and trim low quality reads from fastq files. 
    Return fasta files with reads passed this qc steo and reads removed.

requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  jobid: string
  sequences: File[]

outputs:
  trimmed:
    type: File
    outputSource: trimmed2fasta/file
  rejected:
    type: File
    outputSource: rejected2fasta/file  

steps:

  filter:    
    run: ../Tools/DynamicTrimmer.tool.cwl
    in:
      sequences: sequences
      output:
        source: jobid
        valueFrom: $(self).100.preprocess.length.stats
    out: [trimmed, rejected]

  trimmed2fasta:
    run: ../Tools/seqUtil.tool.cwl
    in:
      sequences: 
        # set format to fastq
        source: filter/trimmed
        valueFrom: |
          ${
            inputs.sequences.format = "fastq" ; return inputs.sequences
          }
      fastq2fasta: 
        default: true
      output:
        source: jobid
        valueFrom: $(self).100.preprocess.passed.fasta
    out: [file]

  rejected2fasta:
    run: ../Tools/seqUtil.tool.cwl
    in:
      sequences: filter/rejected
      fastq2fasta: 
        default: true
      output:
        source: jobid
        valueFrom: $(self).100.preprocess.removed.fasta
    out: [file]

