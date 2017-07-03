cwlVersion: v1.0
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: mgrast/pipeline:4.03
    # dockerPull: mgrast/consensus:1.0

requirements:
  InlineJavascriptRequirement: {}
  SchemaDefRequirement:
    types:
      - $import: FileFormats.cv.yaml
  
stdout: consensus.log
stderr: consensus.error

# PipelineAWE::run_cmd("consensus.py -v -b $max_ln -t $format -i $infile -o $c_stats");

inputs:
  sequences:
    type: File
    doc: Input file, sequence (fasta/fastq).
    format: 
      - format:fasta
      - format:fastq

      # [fasta , fastq , hash]
    inputBinding:
      prefix: --input
  
  basepairs:
    type: int?
    doc: max number of bps to process [default 100]
    inputBinding:
      prefix: --bp_max
  
  stats:
    type: File?
    inputBinding:
      prefix: --stats
  
  output:
    type: string
    doc:  Output file.
    inputBinding:
      prefix: --output

      
  
  
baseCommand: [consensus.py]

arguments: 
  - prefix: --verbose
  - prefix: --type
    valueFrom: |
      ${
         return inputs.sequences.format.split("/").slice(-1)[0]
        } 
 
  
 
    
 
outputs:
  summary:
    type: stdout
  error: 
    type: stderr  
  consensus:
    type: File
    outputBinding: 
      glob: $(inputs.output)
    

$namespaces:
  format: FileFormats.cv.yaml
#  edam: http://edamontology.org/
#  s: http://schema.org/
# $schemas:
#  - http://edamontology.org/EDAM_1.16.owl
#  - https://schema.org/docs/schema_org_rdfa.html

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "MG-RAST"