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
    minQual:
        type: int
        default: 15
    maxLqb:
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
        outputSource: annotate/rnaFeatureOut
    rnaClustSeqOut:
        type: File
        outputSource: annotate/rnaClustSeqOut
    rnaClustMapOut:
        type: File
        outputSource: annotate/rnaClustMapOut
    rnaSimsOut:
        type: File
        outputSource: annotate/rnaSimsOut
    rnaFilterOut:
        type: File
        outputSource: annotate/rnaFilterOut
    simSeqOut:
        type: File
        outputSource: indexSimSeq/simSeqOut
    md5ProfileOut:
        type: File
        outputSource: abundance/md5ProfileOut
    lcaProfileOut:
        type: File
        outputSource: abundance/lcaProfileOut
    sourceStatsOut:
        type: File
        outputSource: abundance/sourceStatsOut

steps:
    preProcess:
        run: ../Workflows/preprocess-fastq.workflow.cwl
        in:
            jobid: jobid
            sequences: sequences
            minQual: minQual
            maxLqb: maxLqb
        out: [passed, removed]
    annotate:
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
    indexSimSeq:
        run: ../Workflows/index_sim_seq.workflow.cwl
        in:
            jobid: string
            featureSeqs:
                source: annotate/rnaFeatureOut
                valueFrom: ${ return [self]; }
            filterSims:
                source: annotate/rnaFilterOut
                valueFrom: ${ return [self]; }
            clustMaps:
                source: annotate/rnaClustMapOut
                valueFrom: ${ return [self]; }
        out: [simSeqOut, indexOut]
    abundance:
        run: ../Workflows/abundance.workflow.cwl
        in:
            jobid: jobid
            md5index: indexSimSeq/indexOut
            filterSims:
                source: annotate/rnaFilterOut
                valueFrom: ${ return [self]; }
            expandSims:
                source: annotate/rnaExpandOut
                valueFrom: ${ return [self]; }
            lcaAnns:
                source: annotate/rnaLCAOut
                valueFrom: ${ return [self]; }
            clustMaps:
                source: annotate/rnaClustMapOut
                valueFrom: ${ return [self]; }
        out: [md5ProfileOut, lcaProfileOut, sourceStatsOut]

