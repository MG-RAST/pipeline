cwlVersion: v1.0
class: CommandLineTool

label: sequence statistics
doc: |
    Calculate statistics for fasta files.
    Output fields:\
      bp_count
      sequence_count
      average_length
      standard_deviation_length
      length_min
      length_max
      average_gc_content
      standard_deviation_gc_content
      average_gc_ratio
      standard_deviation_gc_ratio
      ambig_char_count
      ambig_sequence_count
      average_ambig_chars
      sequence_type

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}
  
stdout: seq_length_stats.stats
stderr: seq_length_stats.error

inputs:
    sequences:
        type: File
        doc: Input file, sequence (fasta/fastq) 
        format: 
            - Formats:fasta
            - Formats:fastq
        inputBinding:
            prefix: --input
  
    outName:
        type: string?
        doc: Output stats file name, if not called prints to STDOUT
        inputBinding:
            prefix: --output
    
    outJson:
        type: boolean?
        doc: Output stats in json format, default is tabbed text
        inputBinding:
            prefix: --json
    
    lenBin:
        type: string?
        doc: Filename to place length bins [default is no output]
        inputBinding:
            prefix: --length_bin
  
    gcBin:
        type: string?
        doc: Filename to place gc bins
        inputBinding:
            prefix: --gc_percent_bin
  
    fast:
        type: boolean?
        doc: Fast stats, length and count only, for protein sequences
        inputBinding:
            prefix: --fast
      
    seqType:
        type: boolean?
        doc: Guess sequence type [wgs|amplicon] from kmer entropy
        inputBinding:
            prefix: --seq_type
  
    seqMax:
        type: int?
        doc: max number of seqs to process (for kmer entropy)
        default: 100000
        inputBinding:
            prefix: --seq_max
              
    ignoreComma:
        type: boolean?
        doc: Ignore commas in header ID
        inputBinding:
            prefix: --ignore_comma

        
baseCommand: [seq_length_stats.py]

arguments: 
    - prefix: --type
      valueFrom: |
          ${
              return inputs.sequences.format.split("/").slice(-1)[0]
          }

outputs:
    stdout:
        type: stdout
    error: 
        type: stderr  
    lenBinOut:
        type: File?
        outputBinding:
            glob: $(inputs.lenBin)
    gcBinOut:
        type: File?
        outputBinding:
            glob: $(inputs.gcBin)
    statOut:   
        type: File?
        outputBinding:
            glob: $(inputs.outName)

$namespaces:
    Formats: FileFormats.cv.yaml

