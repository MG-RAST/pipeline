cwlVersion: v1.0
class: Workflow

label: rna full analysis for fastq files
doc: RNAs - preprocess, annotation, abundance

requirements:
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
    - class: ScatterFeatureRequirement
    - class: MultipleInputFeatureRequirement
    - class: SubworkflowFeatureRequirement

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
    # static DBs
    m5rnaBDB: File
    m5rnaFull: File
    m5rnaClust: File
    m5rnaIndex: Directory
    m5rnaPrefix: string

outputs:
    preProcessPassed:
        type: File
        outputSource: preProcess/passed
    preProcessRemoved:
        type: File
        outputSource: preProcess/removed
    rnaFeatureOut:
        type: File
        outputSource: rnaAnnotate/rnaFeatureOut
    rnaClustSeqOut:
        type: File
        outputSource: rnaAnnotate/rnaClustSeqOut
    rnaClustMapOut:
        type: File
        outputSource: rnaAnnotate/rnaClustMapOut
    rnaSimsOut:
        type: File
        outputSource: rnaAnnotate/rnaSimsOut
    rnaFilterOut:
        type: File
        outputSource: rnaAnnotate/rnaFilterOut
    md5ProfileOut:
        type: File
        outputSource: rnaAbundance/md5ProfileOut
    lcaProfileOut:
        type: File
        outputSource: rnaAbundance/lcaProfileOut
    sourceStatsOut:
        type: File
        outputSource: rnaAbundance/sourceStatsOut

steps:
    preProcess:
        run: ../Workflows/preprocess-fasta.workflow.cwl
        in:
            jobid: jobid
            sequences: sequences
            stats: stats
            filterLn: filterLn
            filterAmbig: filterAmbig
            deviation: deviation
            maxAmbig: maxAmbig
        out: [passed, removed]
    rnaAnnotate:
        run: ../Workflows/rna-annotation.workflow.cwl
        in:
            jobid: jobid
            sequences: preProcess/passed
            m5rnaBDB: m5rnaBDB
            m5rnaFull: m5rnaFull
            m5rnaClust: m5rnaClust
            m5rnaIndex: m5rnaIndex
            m5rnaPrefix: m5rnaPrefix
        out: [rnaFeatureOut, rnaClustSeqOut, rnaClustMapOut, rnaSimsOut, rnaFilterOut, rnaExpandOut, rnaLCAOut]
    rnaAbundance:
        run: ../Workflows/rna-abundance.workflow.cwl
        in:
            jobid: jobid
            rnaExpand: rnaAnnotate/rnaExpandOut
            rnaLCA: rnaAnnotate/rnaLCAOut
            rnaClustMap: rnaAnnotate/rnaClustMapOut
        out: [md5ProfileOut, lcaProfileOut, sourceStatsOut]


