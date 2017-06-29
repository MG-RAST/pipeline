cwlVersion: v1.0
class: CommandLineTool



hints:
  DockerRequirement:
    dockerPull: mgrast/pipeline:4.03
    # dockerPull: mgrast/drisee:1.0
    
requirements:
  InlineJavascriptRequirement: {}
  
stdout: drisee.log
stderr: drisee.error


inputs:
  sequences:
    type: File
    format:
      - format:fasta
      - format:fastq
    inputBinding:
      position: 1
  
baseCommand: [drisee]

arguments: 
  - valueFrom: drisee.stats
    position: 2
  - --verbose 
  - --filter_seq
  - valueFrom: $(runtime.cores)
    prefix: --processes
  - valueFrom: $(runtime.tmpdir)
    prefix: --tmp_dir
  - prefix: --seq_type
    valueFrom: $(inputs.sequences.format)
      # |
      # ${
      #   if (inputs.sequences.format == "http://edamontology.org/format_1929")
      #   { return "fasta" ;}
      #   else { return "fastq";}
      # }
 
outputs:
  info:
    type: stdout
  error: 
    type: stderr  
  stats:
    type: File
    outputBinding: 
      glob: drisee.stats 
    

$namespaces:
  format: FileFormats.cv.yaml

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "MG-RAST"