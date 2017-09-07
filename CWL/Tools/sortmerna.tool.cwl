cwlVersion: v1.0
class: CommandLineTool

label: sortmerna
doc: |
    align rRNA fasta file against clustered rRNA index
    output in blast m8 format
    >sortmerna -a <# core> -m <MB ram> -e 0.1 --blast '1 cigar qcov qstrand' --ref '<refFasta>,<indexDir>/<indexName>' --reads <input> --aligned <input basename>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: sortmerna.log
stderr: sortmerna.error

inputs:
    input:
        type: File
        doc: Input file, sequence (fasta/fastq)
        format:
            - Formats:fasta
            - Formats:fastq
        inputBinding:
            prefix: --reads
    
    refFasta:
        type: File
        doc: Reference .fasta file
    
    indexDir: 
        type: Directory?
        doc: Directory containing index files with prefix INDEXNAME
        default: ./
    
    indexName: 
        type: string
        doc: Prefix for index files
    
    evalue:
        type: float?
        doc: E-value threshold, default 0.1
        default: 0.1
        inputBinding:
            prefix: -e
    

baseCommand: [sortmerna]

arguments:
    - prefix: --blast
      valueFrom: '1 cigar qcov qstrand'
    - prefix: -a
      valueFrom: $(runtime.cores)
    # # Breaks if ram > 999 Mbytes
   #  - prefix: -m
   #    valueFrom: $(runtime.ram)
    - prefix: --ref
      valueFrom: $(inputs.refFasta.path),$(inputs.indexDir.path)/$(inputs.indexName)
    - prefix: --aligned
      valueFrom: $(inputs.input.basename)

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    output:
        type: File?
        doc: Output tab separated aligned file
        outputBinding: 
            glob: $(inputs.input.basename).blast

$namespaces:
    Formats: FileFormats.cv.yaml

