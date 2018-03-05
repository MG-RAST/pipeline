cwlVersion: v1.0
class: Workflow

label: analysis for assembled sequences
doc: rna / protein - qc, annotation, index, abundance

requirements:
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
    - class: ScatterFeatureRequirement
    - class: MultipleInputFeatureRequirement
    - class: SubworkflowFeatureRequirement

inputs:
    jobid: string
    sequences: File
    # static DBs
    m5nrBDB: File
    m5nrFull: File[]
    m5nrSCG: File
    m5rnaFull: File
    m5rnaClust: File
    m5rnaIndex: Directory
    m5rnaPrefix: string

outputs:
    assemblyCoverage:
        type: File
        outputSource: qcAssemble/assemblyCoverage
    seqStatOut:
        type: File
        outputSource: qcAssemble/seqStatFile
    seqBinOut:
        type: File
        outputSource: qcAssemble/seqBinFile
    qcStatOut:
        type: File
        outputSource: qcAssemble/qcStatFile
    qcSummaryOut:
        type: File
        outputSource: qcAssemble/qcSummaryFile
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
    qcAssemble:
        run: ../Workflows/qc-assembled.workflow.cwl
        in:
            jobid: jobid
            sequences: sequences
            kmerLength:
                valueFrom: ${ return [6, 15]; }
        out: [assemblyCoverage, seqStatFile, seqBinFile, qcStatFile, qcSummaryFile]
    rnaAnnotate:
        run: ../Workflows/rna-annotation.workflow.cwl
        in:
            jobid: jobid
            sequences: sequences
            m5nrBDB: m5nrBDB
            m5rnaFull: m5rnaFull
            m5rnaClust: m5rnaClust
            m5rnaIndex: m5rnaIndex
            m5rnaPrefix: m5rnaPrefix
        out: [rnaFeatureOut, rnaClustSeqOut, rnaClustMapOut, rnaSimsOut, rnaFilterOut, rnaExpandOut, rnaLCAOut]
    protAnnotate:
        run: ../Workflows/protein-filter-annotation.workflow.cwl
        in:
            jobid: jobid
            sequences: sequences
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
            coverage: qcAssemble/assemblyCoverage
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
