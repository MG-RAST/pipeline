cwlVersion: v1.0
class: Workflow

label: preprocess fasta
doc: |
    Remove reads from fasta files based on sequence stats.
    Return fasta files with reads passed and reads removed.

requirements:
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
    - class: ScatterFeatureRequirement
    - class: MultipleInputFeatureRequirement

inputs:
    jobid: string
    sequences: File
    stats: File
    filterLn:
        type: boolean
        default: true
    filterAmbig:
        type: boolean
        default: true
    deviation:
        type: float
        default: 2.0
    maxAmbig:
        type: int
        default: 5

outputs:
    passed:
        type: File
        outputSource: filter/passed
    removed:
        type: File
        outputSource: filter/removed

steps:
    filter:
        run: ../Tools/filter_fasta.tool.cwl
        in:
            input: sequences
            stats: stats
            filterLn: filterLn
            filterAmbig: filterAmbig
            deviation: deviation
            maxAmbig: maxAmbig
            outPassed:
                source: jobid
                valueFrom: $(self).100.preprocess.passed.fna
            outRemoved:
                source: jobid
                valueFrom: $(self).100.preprocess.removed.fna
        out: [passed, removed]
