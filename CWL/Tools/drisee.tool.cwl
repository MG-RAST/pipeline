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
      - Formats:fasta
      - Formats:fastq
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
    valueFrom: |
      ${
         return inputs.sequences.format.split("/").slice(-1)[0]
        } 
 
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
  Formats: FileFormats.cv.yaml
#
# s:license: "https://www.apache.org/licenses/LICENSE-2.0"
# s:copyrightHolder: "MG-RAST"