cwlVersion: v1.0
class: CommandLineTool


#PipelineAWE::run_cmd("kmer-tool -l $len -p $proc -i $infile -t $format -o $out_prefix.kmer.$len.stats -f histo -r -d $run_dir");

requirements:
  InlineJavascriptRequirement: {}
  SchemaDefRequirement:
    types:
      - $import: fileFormat.cv.yaml
  
stdout: kmer-tool.log
stderr: kmer-tool.error

# kmer-tool 
  # -l $len 
  # -p $proc 
  # -i $infile 
  # -t $format 
  # -o $out_prefix.kmer.$len.stats 
  # -f histo 
  # -r 
  # -d $run_dir"

inputs:
  sequences:
    type: File
    doc: Input file, sequence (fasta/fastq) or binary count hash (hash).
    format: [fasta , fastq , hash]
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

# kmer-tool 
  # -l $len 
  # -p $proc 
  # -i $infile 
  # -t $format 
  # -o $out_prefix.kmer.$len.stats 
  # -f histo 
  # -r 
  # -d $run_dir"
   
  - valueFrom: $(runtime.cores)
    prefix: --procs
  - prefix: --type
    valueFrom: |
      ${
         return inputs.sequences.format.split("/").slice(-1)[0]
        }
  - prefix: --format 
    valueFrom: histo
  - prefix: --ranked
  - prefix: --tmpdir
    valueFrom: $(runtime.outdir)
  - prefix: --output
    valueFrom: $(inputs.prefix).kmer.$(inputs.length).stats
    
 
outputs:
  summary:
    type: stdout
  error: 
    type: stderr  
  stats:
    type: File
    outputBinding: 
      glob: $(inputs.prefix).kmer.$(inputs.length).stats
    

# $namespaces:
#  edam: http://edamontology.org/
#  s: http://schema.org/
# $schemas:
#  - http://edamontology.org/EDAM_1.16.owl
#  - https://schema.org/docs/schema_org_rdfa.html

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "MG-RAST"