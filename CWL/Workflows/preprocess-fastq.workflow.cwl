cwlVersion: v1.0
class: Workflow

label: preprocess-fastq
doc:  Remove and trim low quality reads from fastq files. 
      Return fasta files with reads passed this qc steo and reads removed.

requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  jobid: string
  sequences: File
  
  kmerLength: 
    type: 
      type: array
      items: int
    default: [6]
  basepairs: int
    
    

outputs:
  someFile:
    type: File
    outputSource: step/output
 
  
  
steps:
  
  filter:    
    run: ../Tools/DynamicTrimmer.tool.cwl
    in:
      sequences: sequences
      output:
        source: jobid
        valueFrom: $(self).100.preprocess.length.stats
      length_bin:
        source: jobid
        valueFrom: $(self).100.preprocess.length.bin
      gc_percent_bin:
        source: jobid
        valueFrom: $(self).100.preprocess.gc.bin
    out: [trimmed , rejected ]
    
  
  fastq2fasta:
    run: ../Tools/seqUtil.tool.cwl
    in:
      sequences: filter/trimmed
      fastq2fasta: 
        valueFrom: true
      output:
        source: jobid
        valueFrom: $(self).100.preprocess.passed.fasta
    out: [file]
    
  fastq2fasta:
    run: ../Tools/seqUtil.tool.cwl
    in:
      sequences: filter/rejected
      fastq2fasta: 
        valueFrom: true
      output:
        source: jobid
        valueFrom: $(self).100.preprocess.removed.fasta      
        
    out: [file]
      