cwlVersion: v1.0
class: Workflow

label: metabarcode (gene amplicon) analysis for fastq files
doc: protein - qc, preprocess, annotation, index, abundance

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
    m5nrBDB: File
    m5nrFull: File[]
    m5nrSCG: File

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
    protFeatureOut:
        type: File
        outputSource: annotate/protFeatureOut
    protClustSeqOut:
        type: File
        outputSource: annotate/protClustSeqOut
    protClustMapOut:
        type: File
        outputSource: annotate/protClustMapOut
    protSimsOut:
        type: File
        outputSource: annotate/protSimsOut
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
        run: ../Workflows/preprocess-fastq.workflow.cwl
        in:
            jobid: jobid
            sequences: sequences
            minQual: minQual
            maxLqb: maxLqb
        out: [trimmed, passed, removed]
    annotate:
        run: ../Workflows/protein-annotation.workflow.cwl
        in:
            jobid: jobid
            sequences: preProcess/passed
            m5nrBDB: m5nrBDB
            m5nrFull: m5nrFull
            m5nrSCG: m5nrSCG
        out: [protFeatureOut, protClustSeqOut, protClustMapOut, protSimsOut, protFilterOut, protExpandOut, protLCAOut, protOntologyOut]
    indexSimSeq:
        run: ../Workflows/index_sim_seq.workflow.cwl
        in:
            jobid: jobid
            featureSeqs:
                source: annotate/protFeatureOut
                valueFrom: ${ return [self]; }
            filterSims:
                source: annotate/protFilterOut
                valueFrom: ${ return [self]; }
            clustMaps:
                source: annotate/protClustMapOut
                valueFrom: ${ return [self]; }
        out: [simSeqOut, indexOut]
    abundance:
        run: ../Workflows/abundance.workflow.cwl
        in:
            jobid: jobid
            md5index: indexSimSeq/indexOut
            filterSims:
                source: annotate/protFilterOut
                valueFrom: ${ return [self]; }
            expandSims:
                source: annotate/protExpandOut
                valueFrom: ${ return [self]; }
            lcaAnns:
                source: annotate/protLCAOut
                valueFrom: ${ return [self]; }
            clustMaps:
                source: annotate/protClustMapOut
                valueFrom: ${ return [self]; }
        out: [md5ProfileOut, lcaProfileOut, sourceStatsOut]

