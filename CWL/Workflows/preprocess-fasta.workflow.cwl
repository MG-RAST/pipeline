cwlVersion: v1.0
class: Workflow

label: filter fasta 
doc: ''

requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  jobid: string
  sequences: File
  stats: File
  
 
    

outputs:
  passed:
    type: File
    outputSource: filter/passed
  removed:
    type: File
    outputSource: filter/removed  
 
  
  
steps:
  
  filter:    
    run: ../Tools/filter_fasta.tool.cwl
    in:
      sequences: sequences
      stats: stats
      output:
        source: jobid
        valueFrom: $(self).100.preprocess.length.stats
    out: [passed , removed]
    
    
    
   
    