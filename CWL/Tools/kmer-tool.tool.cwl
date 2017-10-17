cwlVersion: v1.0
class: CommandLineTool

label: calcualate kmer bins
doc: |
    Script to use jellyfish to get kmer information
    Input:\ fasta/fastq file
    Output:\ kmer information, one of:\
        1. hash:\ binary hash of counts
        2. stats:\ summary stats
        3. dump:\ profile (kmer seq - count)
        4. histo:\ histogram (count - abundance)
        5. histo ranked:\ count, abundance, count*abundance, reverse-sum(abundance), reverse-sum(count*abundance), ratio-to-largest

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}


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
        inputBinding:
            prefix: --input

    length:
        type: int?
        doc: Length of kmer to use, eg. 6 or 15
        default: 6
        inputBinding:
            prefix: --length

    format:
        type: string?
        doc: Output format, one of [hash, stats, dump, histo], default histo
        default: histo
        inputBinding:
            prefix: --format

    maxSize:
        type: float?
        doc: Maximum size (in Gb) to count, files larger are split, default 10.0
        default: 10.0
        inputBinding:
            prefix: --max

    prefix:
        type: string?
        doc: Prefix for output file(s)
        default: qc


baseCommand: [kmer-tool]

arguments:
    - --ranked
    - prefix: --procs
      valueFrom: $(runtime.cores)
    - prefix: --type
      valueFrom: |
          ${
              return inputs.sequences.format.split("/").slice(-1)[0]
          }
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

