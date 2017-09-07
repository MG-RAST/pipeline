cwlVersion: v1.0
class: CommandLineTool

label: seqUtil 
doc:  Convert fastq into fasta and fasta into tab files.

hints:
  DockerRequirement:
    dockerPull: mgrast/pipeline:4.03
    # dockerPull: mgrast/seqUtil:1.0
    
requirements:
  InlineJavascriptRequirement: {}
  
stdout: seqUtil.log
stderr: seqUtil.error


# Usage: seqUtil -i <input> -o <out> <command options>
#
# Options:
#   -h, --help            show this help message and exit
#   -i INPUT, --input=INPUT
#                         input file: must be fasta for
#                         truncate|fasta2tab|fastastd|sortbyid|sortbyid2tab,
#                         tabfile for tab2fasta
#   -o OUT, --output=OUT  output file
#
#   Command Options:
#     --fastq             input file is fastq: for
#                         fasta2tab|sortbyid2tab|uniquefasta
#     --truncate=TRUNCATE
#                         truncate reads to inputed length in bps
#     --truncateuniqueid=TRUNCATEUNIQID
#                         truncate reads to inputted length in bps and replace
#                         seq headers with sequential integers
#     --bowtie_truncate   truncate reads to 1024 bp for bowtie
#     --fastq2uniquefasta
#                         convert fastq to fasta file and replace ids with
#                         compact unique strings
#     --uniquefasta       replace ids with compact unique strings
#     --fastq2fasta       convert fastq to fasta. fast with no qual parsing
#     --fasta2tab         convert fasta to tab file
#     --tab2fasta         convert tab to fasta file
#     --seqstats          fasta stats
#     --stdfasta          convert fasta to standard fasta file
#     --sortbyseq         sort fasta file by sequence length, longest first
#     --sortbyid          sort fasta file by sequence ids
#     --sortbyid2tab      sort fasta file by sequence ids and return as tab file
#     --remove_seqs       remove a list of sequences from a fasta file.
#                         NOTE: list and sequences files must be sorted by id
#     --subset_seqs       return a subset of sequences from a fasta file.
#                         NOTE: list and sequences files must be sorted by id
#     --fastq_random_subset=FASTQ_RANDOM_SUBSET
#                         return a random subset of sequences from a fastq file.
#     --fasta_random_subset=FASTA_RANDOM_SUBSET
#                         return a random subset of sequences from a fasta file.
#     -s SEQ_COUNT, --seq_count=SEQ_COUNT
#                         number of sequences in file, used for *_random_subset.
#     -t TMP_DIR, --tmp_dir=TMP_DIR
#                         sort temp dir, default is '/tmp'
#     -l LIST, --list=LIST
#                         list of sequences sorted
#     -c, --check_sort    checks each fasta id / list id when doing
#                         --remove_seqs or --subset_seqs to see if it sorted.
#                         NOTE: this uses python sort algorithm, results may be
#                         inconsistant if fasta file and list are sorted by unix
#                         or other sort algorithm.


inputs:
  sequences:
    type: File
    format:
      - Formats:fastq
      - Formats:fasta
    inputBinding:
      prefix: --input
  fastq2fasta:
    type: boolean?
    inputBinding:
      prefix: --fastq2fasta
  fasta2tab:
    type: boolean?
    inputBinding:
      prefix: --fasta2tab
  sortbyid2tab:
    type: boolean?
    inputBinding:
      prefix: --sortbyid2tab
  bowtie_truncate:
    type: boolean?
    inputBinding:
      prefix: --bowtie_truncate    
  output: 
    type: string
    inputBinding:  
      prefix: --output      
      
baseCommand: [seqUtil]

arguments: 
  # - prefix: --output
  #   valueFrom: $(inputs.sequences.nameroot).fasta
  - prefix:
    valueFrom: |
        ${
           if (  ("format" in inputs.sequences) && (inputs.sequences.format.split("/").slice(-1)[0] == "fastq")  ) { return "--fastq"; } else { return "" ; }  
         }
    

 # return inputs.sequences.format.split("/").slice(-1)[0]

 
outputs:
  info:
    type: stdout
  error: 
    type: stderr  
  file:
    type: File
    format: |
        ${
          if (inputs.fasta2tab) 
              { return "tsv" ;}
          else if (inputs.sortbyid2tab) 
              { return "tsv" ;}
          else if (inputs.fastq2fasta) 
              { return "fasta";}
          else if (inputs.sequences.format) 
              { return inputs.sequences.format ;}
          else { return '' ;}
          return "" ;
        }
    outputBinding: 
      glob: $(inputs.output)
    

$namespaces:
  Formats: FileFormats.cv.yaml
#
# s:license: "https://www.apache.org/licenses/LICENSE-2.0"
# s:copyrightHolder: "MG-RAST"