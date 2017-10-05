cwlVersion: v1.0
class: Workflow

label: preprocess - fastq2fasta
doc:  Convert fastq to fasta only

requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  jobid: string
  sequences: File
  
  
    

outputs:
  trimmed:
    type: File
    outputSource: trimmed2fasta/file
  rejected:
    type: File
    outputSource: rejected2fasta/file  
 
  
  
steps:
  
  
  trimmed2fasta:
    run: ../Tools/seqUtil.tool.cwl
    in:
      sequences: sequences
      fastq2fasta: 
        default: true
      output:
        source: jobid
        valueFrom: $(self).100.preprocess.passed.fasta
    out: [file]
 
  # Create zero sized file, only important for bookkeeping and if subworkflows are chained together  
  rejected2fasta:
    run:
      cwlVersion: v1.0
      class: CommandLineTool
      baseCommand: [touch]
      inputs:
        filename:
          type: string
          inputBinding:
            position: 1
      outputs: 
        file:
          type: File
          outputBinding:
            glob: $(inputs.filename)  
          
    in:
      filename: 
        source: jobid
        valueFrom: $(self).100.preprocess.removed.fasta      
        
    out: [file]
      