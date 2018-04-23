cwlVersion: v1.0
class: CommandLineTool

label: FragGeneScan
doc: |
    hidden Markov model for predicting prokaryotic coding regions
    >run_FragGeneScan.pl --genome <input> --out <output> --complete 0 --train 454_30

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: run_FragGeneScan.log
stderr: run_FragGeneScan.error

inputs:
    input:
        type: File
        doc: Input fasta format file
        format:
            - Formats:fasta
        inputBinding:
            prefix: --genome
    
    complete:
        type: int?
        doc: |
            1 if the sequence file has complete genomic sequences
            0 if the sequence file has short sequence reads
            default is 0
        default: 0
        inputBinding:
            prefix: --complete
    
    train:
        type: string?
        doc: Training model to use, default is 454_30
        default: "454_30"
        format:
            - Types:complete
            - Types:sanger_5
            - Types:sanger_10
            - Types:454_5
            - Types:454_10
            - Types:454_30
            - Types:illumina_5
            - Types:illumina_10
        inputBinding:
            prefix: --train
    
    outName:
        type: string
        doc: Output name
        inputBinding:
            prefix: --out


baseCommand: [run_FragGeneScan.pl]

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    outDNA:
        type: File
        doc: Output .ffn (dna) file
        outputBinding: 
            glob: $(inputs.outName).ffn
    outProt:
        type: File
        doc: Output .faa (protein) file
        outputBinding: 
            glob: $(inputs.outName).faa

$namespaces:
    Formats: FileFormats.cv.yaml
    Types: FragGeneScanTypes.cv.yaml

