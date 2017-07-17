cwlVersion: v1.0
class: Workflow

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
    run: ../Tools/filter_fasta.tool.cwl
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
    out: [stats , len_bin , gc_bin]
    