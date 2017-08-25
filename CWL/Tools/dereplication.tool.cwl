cwlVersion: v1.0
class: CommandLineTool

label: dereplication 
doc:  Convert fastq into fasta and fasta into tab files.

hints:
  DockerRequirement:
    dockerPull: mgrast/pipeline:4.03
    # dockerPull: mgrast/dereplication:1.0
    
requirements:
  InlineJavascriptRequirement: {}
  
stdout: dereplication.log
stderr: dereplication.error


# Usage: dereplication.py [options] input_fasta output_name
#
#
# Options:
#   -h, --help            show this help message and exit
#   -l PREFIX_LENGTH, --prefix_length=PREFIX_LENGTH
#                         Length of prefix [default '50']
#   -s SEQ_TYPE, --seq_type=SEQ_TYPE
#                         Sequence type: fasta, fastq [default 'fasta']
#   -o O_FORMAT, --o_format=O_FORMAT
#                         Output file format: fasta, fastq [default 'fasta']
#   -d TMPDIR, --tmp_dir=TMPDIR
#                         DIR for sorting files (must be full path) [default
#                         '/tmp']
#   -m MEMORY, --memory=MEMORY
#                         Memory for sorting in GB [default 4]


inputs:
  sequences:
    type: File
    format:
      - Formats:fastq
      - Formats:fasta
    inputBinding:
      position: 1
       
  outputPrefix: 
    type: string
    inputBinding:  
      position: 2   
      
  prefixLength:
    type: int
    default: 50
    inputBinding:
      prefix: --prefix_length  
      
  outputFormat:
    type: 
      type: enum
      symbols:
        - fasta 
        - fastq
      inputBinding:
        prefix:  --o_format  
    default: fasta
    
      
baseCommand: [dereplication.py]

arguments:
  - prefix: --memory
    valueFrom: $(runtime.ram)
  - prefix: --tmp_dir
    valueFrom: $(runtime.tmpdir)
  - prefix: --seq_type
    valueFrom: |
        ${
          if (inputs.sequences.format) {
            if ( inputs.sequences.format.split("/").slice(-1)[0] == "fastq"  ) { return "fastq"; } 
            else { return "fasta" ; }
            }
          else { return "fasta"}  
        }  

outputs:
  info:
    type: stdout
  error: 
    type: stderr  
  passed:
    type: File
    format: $(inputs.outputFormat)
    outputBinding: 
      glob: $(inputs.outputPrefix).passed.*
  removed:
    type: File
    format: $(inputs.outputFormat)
    outputBinding: 
      glob: $(inputs.outputPrefix).removed.*    
  derep:
    type: File
    format: tsv
    outputBinding: 
      glob: $(inputs.outputPrefix).derep    
    

$namespaces:
  Formats: FileFormats.cv.yaml
#
# s:license: "https://www.apache.org/licenses/LICENSE-2.0"
# s:copyrightHolder: "MG-RAST"