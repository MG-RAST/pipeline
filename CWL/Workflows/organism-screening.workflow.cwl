cwlVersion: v1.0
class: Workflow

label: screen out taxa
doc:  Remove sequences which align against a reference set. The references are preformatted (index files)

requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  stage: 
    type: string
    doc:  Stage ID used by MG-RAST for identification
    default: "200"
    # inputBinding:
    #   valueFrom: '200'
  jobid: string
  sequences: File
  indexDir: Directory
  indexName: string
  
  
    

outputs:
  passed:
    type: File
    outputSource: screen/unaligned
  
  
steps:
    
  truncate:
    run: ../Tools/seqUtil.tool.cwl
    in:
      sequences: sequences
      bowtie_truncate:
        default: true
      output:  
        source: [jobid,stage]
        valueFrom: $(self[0]).$(self[1]).screen.truncated.fasta         
    out: [file]
 
  # Create zero sized file, only important for bookkeeping and if subworkflows are chained together  
  screen:
    run: ../Tools/bowtie2.tool.cwl       
    in:
      sequences: truncate/file
      indexDir: indexDir
      indexName: indexName
      outUnaligned: 
        source: [jobid,stage]
        valueFrom: $(self[0]).$(self[1]).preprocess.passed.fasta             
    out: [unaligned]
      