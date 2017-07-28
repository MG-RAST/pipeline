cwlVersion: v1.0
class: CommandLineTool

label: rna screening
doc:  |
    identify potential rRNAs based on match to clustered rRNA DB:
    >sortmerna -a $proc -m $mem -e $eval --blast '1 cigar qcov qstrand' --ref '$rna_nr,$index' --reads $fasta --aligned $fasta 

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: sortmerna.log
stderr: sortmerna.error

inputs:
    sequences:
        type: File
        doc: Input file, sequence (fasta/fastq)
        format:
            - Formats: fasta
            - Formats: fastq
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
        type: float
        doc: E-value threshold
        inputBinding:
            prefix: -e
    

baseCommand: [sortmerna]

arguments:
    - prefix: --blast
      valueFrom: '1 cigar qcov qstrand'
    - prefix: -a
      valueFrom: $(runtime.cores)
    - prefix: -m
      valueFrom: $(runtime.ram)
    - prefix: --ref
      valueFrom: $(inputs.refFasta.path),$(inputs.indexDir.path)/$(inputs.indexName)
    - prefix: --aligned
      valueFrom: $(inputs.sequences.basename)

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    aligned:
        type: File
        outputBinding: 
            glob: $(inputs.sequences.basename).blast

$namespaces:
    Formats: FileFormats.cv.yaml

