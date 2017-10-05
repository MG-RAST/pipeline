cwlVersion: v1.0
class: CommandLineTool

label: filter fasta
doc: |
    filter fasta file based on sequence length and/or on number of ambiguity characters (Ns)
    skipping both filters is equivalent to copying the file, but slower

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: filter_fasta.log
stderr: filter_fasta.error

inputs:
    input:
        type: File
        doc: input fasta sequence file
        format:
            - Formats:fasta
        inputBinding:
            prefix: -input
    
    stats:
        type: File
        doc: input sequence stats file, json format
        format:
            - Formats:json
        inputBinding:
            prefix: -stats
    
    filterLn:
        type: boolean?
        doc: flag to request filtering on sequence length
        default: true
        inputBinding:
            prefix: -filter_ln
    
    filterAmbig:
        type: boolean?
        doc: flag to request filtering on ambiguity characters
        default: true
        inputBinding:
            prefix: -filter_ambig
    
    deviation:
        type: float?
        doc: stddev mutliplier for calculating min / max length for rejection
        default: 2.0
        inputBinding:
            prefix: -deviation
    
    maxAmbig:
        type: int?
        doc: maximum number of ambiguity characters (Ns) in a sequence which will not be rejected
        default: 5
        inputBinding:
            prefix: -max_ambig
    
    outPassed:
        type: string
        doc: output passed sequences
        inputBinding:
            prefix: -output
    
    outRemoved:
        type: string
        doc: output removed sequences
        inputBinding:
            prefix: -removed


baseCommand: [filter_fasta.pl]

outputs:
    info:
        type: stdout
    error:
        type: stderr
    passed:
        type: File
        outputBinding:
            glob: $(inputs.outPassed)
    removed:
        type: File
        outputBinding:
            glob: $(inputs.outRemoved)

$namespaces:
    Formats: FileFormats.cv.yaml

