cwlVersion: v1.0
class: CommandLineTool



hints:
  DockerRequirement:
    dockerPull: mgrast/pipeline:4.03
    # dockerPull: mgrast/filter_fasta:1.0
    
requirements:
  InlineJavascriptRequirement: {}
  
stdout: filter_fasta.log
stderr: filter_fasta.error



  # -input         input fasta sequence file (required)
  # -stats         input sequence stats file, json format (required)
  # -output        output fasta file (required)
  # -removed       removed fasta file, sequences which are filtered out will get written to the specified file
  #
  # -filter_ln     flag to request filtering on sequence length
  # -filter_ambig  flag to request filtering on ambiguity characters
  # -deviation     stddev mutliplier for calculating min / max length for rejection
  # -max_ambig     maximum number of ambiguity characters (Ns) in a sequence which will not be rejected

inputs:
  sequences:
    doc: input fasta sequence file 
    type: File
    format:
      - Formats:fasta
    inputBinding:
      prefix: -input
  stats:
    doc: input sequence stats file, json format 
    type: File
    format:
      - Formats:json
    inputBinding:
      prefix: -stats  
  
baseCommand: [filter_fasta.pl]

arguments: 
  - prefix: --output
    valueFrom: $(inputs.sequences.basename).passed
  - prefix: --removed
    valueFrom: $(inputs.sequences.basename).removed
  
  
 
outputs:
  info:
    type: stdout
  error: 
    type: stderr  
  passed:
    type: File
    outputBinding: 
      glob: $(inputs.sequences.basename).passed
  removed:
    type: File
    outputBinding: 
      glob: $(inputs.sequences.basename).removed
    

$namespaces:
  Formats: FileFormats.cv.yaml
#
# s:license: "https://www.apache.org/licenses/LICENSE-2.0"
# s:copyrightHolder: "MG-RAST"