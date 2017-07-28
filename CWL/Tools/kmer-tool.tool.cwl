cwlVersion: v1.0
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: mgrast/pipeline:4.03
    # dockerPull: mgrast/kmerTool:1.0
  # Shock:
#     createAttributes:
#       input: [ToolName , $(outputs).stats , $(outpus).summary]
#       run: createAttr.pl
#       mapping:
#         stats:
#           glob: $(outputs).stats.attr
#         summary:
#           glob: $(outpus).summary.attr

requirements:
  InlineJavascriptRequirement: {}
  # SchemaDefRequirement:
#     types:
#       - $import: FileFormats.cv.yaml
  
  
stdout: kmer-tool.log
stderr: kmer-tool.error

inputs:
  sequences:
    type: File
    doc: Input file, sequence (fasta/fastq) or binary count hash (hash).
    format: 
      - Formats:fasta
      - Formats:fastq
      - Formats:hash
      # [fasta , fastq , hash]
    inputBinding:
      prefix: --input
  
  length:
    type: int
    doc: Length of kmer to use, eg. 6 or 15
    default: 6
    inputBinding:
      prefix: --length
  
  prefix:
    type: string
    doc: Prefix for output file(s)
    default: qc

      
  
  
baseCommand: [kmer-tool]

arguments: 
   
  - valueFrom: $(runtime.cores)
    prefix: --procs
  - prefix: --type
    valueFrom: |
      ${
         return inputs.sequences.format.split("/").slice(-1)[0]
        }
  - prefix: --format 
    valueFrom: histo
  - --ranked
  - prefix: --tmpdir
    valueFrom: $(runtime.outdir)
  - prefix: --output
    valueFrom: $(inputs.prefix).kmer.$(inputs.length).stats
    
 
outputs:
  summary:
    type: stdout
  error: 
    type: stderr  
  # stats:
#     type: File
#     outputBinding:
#       glob: $(inputs.prefix).kmer.$(inputs.length).stats
  stats:
    type:       
      type: record
      label: none
      fields:
        - name: length
          type: int
          outputBinding:
            outputEval: $(inputs.length)
             
        - name: file 
          type: File 
          outputBinding:
            glob: $(inputs.prefix).kmer.$(inputs.length).stats 

$namespaces:
  format: FileFormats.cv.yaml
# #  edam: http://edamontology.org/
# #  s: http://schema.org/
# # $schemas:
# #  - http://edamontology.org/EDAM_1.16.owl
# #  - https://schema.org/docs/schema_org_rdfa.html
#
# s:license: "https://www.apache.org/licenses/LICENSE-2.0"
# s:copyrightHolder: "MG-RAST"