cwlVersion: v1.0
class: CommandLineTool


#PipelineAWE::run_cmd("drisee -v -p $proc -t $format -d $run_dir -f $infile $d_stats > $d_info", 1);

requirements:
  InlineJavascriptRequirement: {}
  
stdout: drisee.log
stderr: drisee.error


inputs:
  sequences:
    type: File
    format:
      - edam:format_1929 # FASTA
      - edam:format_1930 # FASTQ
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
        if (inputs.sequences.format == "http://edamontology.org/format_1929")
        { return "fasta" ;}
        else { return "fastq";}
      }
 
outputs:
  summary:
    type: stdout
  error: 
    type: stderr  
  stats:
    type: File
    outputBinding: 
      glob: drisee.stats 
    

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/docs/schema_org_rdfa.html

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "MG-RAST"