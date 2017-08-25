cwlVersion: v1.0
class: Workflow


inputs:
  sequences: File
  
outputs:
  sequenceStatsFile:
    type: File
    outputSource: getSequenceHeader/output
  # checked:
  #   type: File
  #   outputSource: checkSequenceHeader/output

steps:
  
  getSequenceHeader:
    run: ../Tools/template.tool.cwl
    in:
      sequences: sequences

    out: [ output , error ]
   
  checkSequenceHeader:
    run: ../Tools/template.tool.cwl
    in:
      sequences: getSequenceHeader/output

    out: [ output , error ]