cwlVersion: v1.0
class: CommandLineTool

label: dereplication 
doc:  Keep only one of sequence sets with identical prefixes

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03
    
requirements:
    InlineJavascriptRequirement: {}
  
stdout: dereplication.log
stderr: dereplication.error

inputs:
    sequences:
        type: File
        format:
            - Formats:fastq
            - Formats:fasta
        inputBinding:
            position: 1

    outPrefix:
        type: string
        inputBinding:  
            position: 2

    prefixLength:
        type: int?
        default: 50
        inputBinding:
            prefix: --prefix_length

    inFormat:
        type:
            type: enum
            symbols:
                - fasta 
                - fastq
            inputBinding:
                prefix:  --seq_type
        default: fasta
    
    outFormat:
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

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    passed:
        type: File
        format: $(inputs.outFormat)
        outputBinding: 
            glob: $(inputs.outPrefix).passed.*
    removed:
        type: File
        format: $(inputs.outFormat)
        outputBinding: 
            glob: $(inputs.outPrefix).removed.*    
    derep:
        type: File
        format: tsv
        outputBinding: 
            glob: $(inputs.outPrefix).derep    

$namespaces:
  Formats: FileFormats.cv.yaml

