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
  
  step1:
    
  step2:
    