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
      

requirements:
  InlineJavascriptRequirement: {}
  # SchemaDefRequirement:
#     types:
#       - $import: FileFormats.cv.yaml
  
  
stdout: format_qc_stats.stats
stderr: format_qc_stats.error


inputs:
  
  kmer:
    type: 
      type: array
      items: 
        type: record
        fields:
          length: int
          file: File
  
  drisee_stat:
    doc: drisee stat file
    type: File
    inputBinding:
      prefix: -drisee_stat
  
  drisee_info:
    type: File
    doc: drisee info file
    inputBinding:
      prefix: -drisee_info
      
  # kmer_lens:
  #   type: string
  #   doc: kmer len list
  #   inputBinding:
  #     prefix: -kmer_lens
  #
  # kmer_stats:
  #   type: string
  #   doc: comma separated list of kmer_stats files
  #   inputBinding:
  #     prefix: -kmer_stats
  #    
  consensus:
    type: File
    doc: consensus stat file
    inputBinding:
      prefix: -consensus
    
  coverage:
    type: File?
    doc: coverage stat file
    inputBinding:
      prefix: -coverage  
    
  output_prefix:
    type: string
    doc: output prefix = ${output_prefix}.seq.bins, ${output_prefix}.seq.stats
    inputBinding: 
      prefix: -out_prefix    
  
                     
baseCommand: [format_qc_stats.pl]

arguments:
  - prefix: -kmer_lens
    valueFrom: |
      ${
         return inputs.kmer.map( 
           function(r){ return r.length }
           ).join() 
        }
  - prefix: -kmer_stats
    valueFrom: |
      ${
         return inputs.kmer.map( 
           function(r){ return r.file.path }
           ).join() 
        }      
 
outputs:
  stats:
    type: File
    outputBinding:
      glob: $(inputs.output_prefix).qc.stats
    
  error: 
    type: stderr  
  summary:
    type: File
    outputBinding:
      glob: $(inputs.output_prefix).qc.summary
  


# $namespaces:
#   s: http://schema.org/
# #  edam: http://edamontology.org/
#
# $schemas:
#   - https://schema.org/docs/schema_org_rdfa.html
# # #  - http://edamontology.org/EDAM_1.16.owl
# #
# #
# s:license: "https://www.apache.org/licenses/LICENSE-2.0"
# s:copyrightHolder: "MG-RAST"