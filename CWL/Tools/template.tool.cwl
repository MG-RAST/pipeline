cwlVersion: v1.0
class: CommandLineTool
baseCommand: [fgrep , '>' ]

hints:
  DockerRequirement:
    dockerPull: mgrast/pipeline:4.03

  # Shock:
  #   createAttributes:
  #     - in: [ $(outputs.stats) , $(outputs.summary)]
  #       run: ../createAttr.tool.cwl
  #       type: none
  #       requirements: none
  #       out: [ summaryAttr , passedAttr]
  #       out:
  #         - glob: $(outputs.stats).attr
  #         - glob: $(outputs.summary).attr
  #       mapping:
  #           - $(outputs.stats):
  #             glob: $(outputs.stats).attr
  #           - $(outputs.summary):
  #             glob: $(outputs.summary).attr
  #   createSubset:
  #     - in:
  #         sequences: $(inputs.sequences)
  #         results:  $(outputs.summary)
  #       run: ../createSubset.tool.cwl
  #       type: none
  #       requirements: none
  #       out: $(outputs.summary)

  
stdout: template.log
stderr: template.error

inputs:
  sequences:
    type: File
    format:
      - format:fasta
      - format:fastq
    inputBinding:
      position: 2 
  count:
    type: int                                   
    
outputs:
  output:
    type: stdout
  error: 
    type: stderr 
  struct:
    type:       
      type: record
      label: none
      fields:
        - name: length
          type: int
          outputBinding:
            outputEval: $(inputs.count)
             
        - name: file 
          type: File 
          outputBinding:
            glob: template.log

$namespaces:
  format: FileFormats.cv.yaml
  s: https://schema.org
  
$schemas:
  - https://schema.org/docs/schema_org_rdfa.html
  
s:license: "https://www.apache.org/licenses/LICENSE-2.0"