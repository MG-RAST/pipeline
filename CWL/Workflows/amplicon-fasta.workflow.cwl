cwlVersion: v1.0
class: Workflow

label: rna amplicon analysis for fasta files
doc: RNAs - qc, preprocess, annotation, index, abundance

requirements:
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
    - class: ScatterFeatureRequirement
    - class: MultipleInputFeatureRequirement
    - class: SubworkflowFeatureRequirement

inputs:
    jobid: string
    sequences: File
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
    m5nrBDB: File
    m5rnaFull: File
    m5rnaClust: File
    m5rnaIndex: Directory
    m5rnaPrefix: string

outputs:
    seqStatOut:
        type: File
        outputSource: qcBasic/seqStatFile
    seqBinOut:
        type: File
        outputSource: qcBasic/seqBinFile
    qcStatOut:
        type: File
        outputSource: qcBasic/qcStatFile
    qcSummaryOut:
        type: File
        outputSource: qcBasic/qcSummaryFile
    adapterPassed:
        type: File
        outputSource: preProcess/trimmed
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
    qcBasic:
        run: ../Workflows/qc-basic.workflow.cwl
        in:
            jobid: jobid
            sequences: sequences
            kmerLength:
                valueFrom: ${ return [6, 15]; }
        out: [seqStatFile, seqBinFile, qcStatFile, qcSummaryFile]
    preProcess:
        run: ../Workflows/preprocess-fasta.workflow.cwl
        in:
            jobid: jobid
            sequences: sequences
            stats: qcBasic/seqStatFile
            filterLn: filterLn
            filterAmbig: filterAmbig
            deviation: deviation
            maxAmbig: maxAmbig
        out: [trimmed, passed, removed]
    annotate:
        run: ../Workflows/rna-annotation.workflow.cwl
        in:
            jobid: jobid
            sequences: preProcess/passed
            m5nrBDB: m5nrBDB
            m5rnaFull: m5rnaFull
            m5rnaClust: m5rnaClust
            m5rnaIndex: m5rnaIndex
            m5rnaPrefix: m5rnaPrefix
        out: [rnaFeatureOut, rnaClustSeqOut, rnaClustMapOut, rnaSimsOut, rnaFilterOut, rnaExpandOut, rnaLCAOut]
    indexSimSeq:
        run: ../Workflows/index_sim_seq.workflow.cwl
        in:
            jobid: jobid
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

