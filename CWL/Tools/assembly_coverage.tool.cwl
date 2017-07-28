cwlVersion: v1.0
class: CommandLineTool



hints:
  DockerRequirement:
    dockerPull: mgrast/pipeline:4.03
    # dockerPull: mgrast/drisee:1.0
    
requirements:
  InlineJavascriptRequirement: {}
  
stdout: assembly_coverage.log
stderr: assembly_coverage.error


inputs:
  sequences:
    type: File
    format:
      - Formats:fasta
      - Formats:fastq
    inputBinding:
      prefix: --input
      position: 1
  
baseCommand: [assembly_coverage.py]

arguments: 
  - prefix: --type
    valueFrom: |
      ${
         return inputs.sequences.format.split("/").slice(-1)[0]
        } 
  - prefix: --output
    valueFrom: coverage.tsv
 
outputs:
  info:
    type: stdout
  error: 
    type: stderr  
  coverage:
    type: File
    outputBinding: 
      glob: coverage.tsv
    

$namespaces:
  Formats: FileFormats.cv.yaml
#
# s:license: "https://www.apache.org/licenses/LICENSE-2.0"
# s:copyrightHolder: "MG-RAST"