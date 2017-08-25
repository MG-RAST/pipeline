cwlVersion: v1.0
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: mgrast/pipeline:4.03
    # dockerPull: mgrast/seqLengthStats:1.0

  # Shock:
 #    createAttributes:
 #      - in: [ $(outputs.stats) , $(outputs.summary)]
 #        run: ../createAttr.tool.cwl
 #        type: none
 #        requirements: none
 #        out: [ summaryAttr , passedAttr]
 #        out:
 #          - glob: $(outputs.stats).attr
 #          - glob: $(outputs.summary).attr
 #        mapping:
 #            - $(outputs.stats):
 #              glob: $(outputs.stats).attr
 #            - $(outputs.summary):
 #              glob: $(outputs.summary).attr
 #    createSubset:
 #      - in:
 #          sequences: $(inputs.sequences)
 #          results:  $(outputs.summary)
 #        run: ../createSubset.tool.cwl
 #        type: none
 #        requirements: none
 #        out: $(outputs.summary)
 #
      


  
  
stdout: format_seq_stats.stats
stderr: format_seq_stats.error

inputs:
  sequence_stats:
    doc: stats tabbed file
    type: File
    inputBinding:
      prefix: -seq_stat
  
  sequence_lengths:
    type: File
    doc: len bin file
    inputBinding:
      prefix: -seq_lens
      
  sequence_gc:
    type: File
    doc: gc bin file
    inputBinding:
      prefix: -seq_gc
      
  output_prefix:
    type: string
    doc: output prefix, e.g. ${output_prefix}.seq.bins, ${output_prefix}.seq.stats
    inputBinding: 
      prefix: -out_prefix
                    
baseCommand: [format_seq_stats.pl]

 
outputs:
  stats:
    type: File
    format: json
    outputBinding:
      glob: $(inputs.output_prefix).seq.stats
    
  error: 
    type: stderr  
  bins:
    type: File
    outputBinding:
      glob: $(inputs.output_prefix).seq.bins
  


# $namespaces:
#   s: http://schema.org/
# #  edam: http://edamontology.org/
#
# $schemas:
#    - https://schema.org/docs/schema_org_rdfa.html
# # #  - http://edamontology.org/EDAM_1.16.owl
# #
# #
# s:license: "https://www.apache.org/licenses/LICENSE-2.0"
# s:copyrightHolder: "MG-RAST"