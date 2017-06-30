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
  SchemaDefRequirement:
    types:
      - $import: FileFormats.cv.yaml
  
  
stdout: seq_length_stats.stats
stderr: seq_length_stats.error

inputs:
  sequences:
    type: File
    doc: Input file, sequence (fasta/fastq) 
    format: 
      - ff:fasta
      - ff:fastq
    inputBinding:
      prefix: --input
  
  output:
    type: string?
    doc: Output stats file, if not called prints to STDOUT
    inputBinding:
      prefix: --output
    
  length_bin:
    type: string?
    doc: File to place length bins [default is no output]
    inputBinding:
      prefix: --length_bin
  
  gc_percent_bin:
    type: string?
    doc:
    inputBinding:
      prefix: --gc_percent_bin
  
  fast:
    type: boolean
    default: false
    inputBinding:
      prefix: --fast
      
  guess_seq_type:
    type: boolean
    default: false
    inputBinding:
      prefix: --seq_type
  
  seq_max:
    type: int?
    doc: max number of seqs to process (for kmer entropy)
    default: 100000
    inputBinding:
      prefix: --seq_max
              
  ignore_comma:
    type: boolean
    default: false
    doc: Ignore commas in header ID
    inputBinding:
      prefix: --ignore_comma

        
baseCommand: [seq_length_stats.py]

arguments: 
   
  - prefix: --type
    valueFrom: |
      ${
         return inputs.sequences.format.split("/").slice(-1)[0]
        }
    
 
outputs:
  stats:
    type: stdout
  error: 
    type: stderr  
  len_bin:
    type: File?
    outputBinding:
      glob: $(inputs.length_bin)
  gc_bin:
    type: File?
    outputBinding:
      glob: $(inputs.gc_percent_bin)    


$namespaces:
  ff: FileFormats.cv.yaml
  # s: http://schema.org/
#  edam: http://edamontology.org/

# $schemas:
#   - https://schema.org/docs/schema_org_rdfa.html
# #  - http://edamontology.org/EDAM_1.16.owl
#
#
# s:license: "https://www.apache.org/licenses/LICENSE-2.0"
# s:copyrightHolder: "MG-RAST"