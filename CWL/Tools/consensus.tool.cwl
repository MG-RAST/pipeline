cwlVersion: v1.0
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: mgrast/pipeline:4.03
    # dockerPull: mgrast/consensus:1.0

requirements:
  InlineJavascriptRequirement: {}

  
stdout: consensus.log
stderr: consensus.error


inputs:
  sequences:
    type: File
    doc: Input file, sequence (fasta/fastq).
    format: 
      - Formats:fasta
      - Formats:fastq

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
  - valueFrom: --verbose
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
  Formats: FileFormats.cv.yaml
