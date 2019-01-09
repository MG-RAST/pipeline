cwlVersion: v1.0
class: Workflow

label: WGS and MT analysis for fastq files
doc: rna / protein - qc, preprocess, filter, annotation, index, abundance

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
    derepPrefix:
        type: int
        default: 50
    # static DBs
    indexDir: Directory
    indexName:
        type: string?
        default: h_sapiens
    m5nrBDB: File
    m5nrFull: File[]
    m5nrSCG: File
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
    dereplicationPassed:
        type: File
        outputSource: dereplication/passed
    dereplicationRemoved:
        type: File
        outputSource: dereplication/removed
    orgScreenPassed:
        type: File
        outputSource: orgScreen/passed
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
    protFeatureOut:
        type: File
        outputSource: protAnnotate/protFeatureOut
    protFilterFeatureOut:
        type: File
        outputSource: protAnnotate/protFilterFeatureOut
    protClustSeqOut:
        type: File
        outputSource: protAnnotate/protClustSeqOut
    protClustMapOut:
        type: File
        outputSource: protAnnotate/protClustMapOut
    protSimsOut:
        type: File
        outputSource: protAnnotate/protSimsOut
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
    darkmatterOut:
        type: File
        outputSource: darkmatter/output

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
    dereplication:
        run: ../Tools/dereplication.tool.cwl
        in:
            sequences: preProcess/passed
            prefixLength: derepPrefix
            inFormat:
                valueFrom: fasta
            outFormat:
                valueFrom: fasta
            outPrefix:
                source: jobid
                valueFrom: $(self).150.dereplication
        out: [passed, removed]
    orgScreen:
        run: ../Workflows/organism-screening.workflow.cwl
        in:
            jobid: jobid
            sequences: dereplication/passed
            indexDir: indexDir
            indexName: indexName
        out: [passed]
    rnaAnnotate:
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
    protAnnotate:
        run: ../Workflows/protein-filter-annotation-diamond.workflow.cwl
        in:
            jobid: jobid
            sequences: orgScreen/passed
            rnaSims: rnaAnnotate/rnaSimsOut
            rnaClustMap: rnaAnnotate/rnaClustMapOut
            m5nrBDB: m5nrBDB
            m5nrFull: m5nrFull
            m5nrSCG: m5nrSCG
        out: [protFeatureOut, protFilterFeatureOut, protClustSeqOut, protClustMapOut, protSimsOut, protFilterOut, protExpandOut, protLCAOut]
    indexSimSeq:
        run: ../Workflows/index_sim_seq.workflow.cwl
        in:
            jobid: jobid
            featureSeqs:
                source:
                    - rnaAnnotate/rnaFeatureOut
                    - protAnnotate/protFeatureOut
            filterSims:
                source:
                    - rnaAnnotate/rnaFilterOut
                    - protAnnotate/protFilterOut
            clustMaps:
                source:
                    - rnaAnnotate/rnaClustMapOut
                    - protAnnotate/protClustMapOut
        out: [simSeqOut, indexOut]
    abundance:
        run: ../Workflows/abundance-clca.workflow.cwl
        in:
            jobid: jobid
            md5index: indexSimSeq/indexOut
            filterSims:
                source:
                    - rnaAnnotate/rnaFilterOut
                    - protAnnotate/protFilterOut
            expandSims:
                source:
                    - rnaAnnotate/rnaExpandOut
                    - protAnnotate/protExpandOut
            rnaExpandLca: rnaAnnotate/rnaLCAOut
            protExpandLca: protAnnotate/protLCAOut
            rnaClustMap: rnaAnnotate/rnaClustMapOut
            protClustMap: protAnnotate/protClustMapOut
            m5nrSCG: m5nrSCG
        out: [md5ProfileOut, lcaProfileOut, sourceStatsOut]
    darkmatter:
        run: ../Tools/extract_darkmatter.tool.cwl
        in:
            geneSeq: protAnnotate/protFilterFeatureOut
            simHit:
                source:
                    - rnaAnnotate/rnaSimsOut
                    - protAnnotate/protSimsOut
            clustMap:
                source:
                    - rnaAnnotate/rnaClustMapOut
                    - protAnnotate/protClustMapOut
            outName:
                source: jobid
                valueFrom: $(self).750.darkmatter.faa
        out: [output]
