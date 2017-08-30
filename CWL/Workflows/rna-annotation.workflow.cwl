cwlVersion: v1.0
class: Workflow

label: rna annotation
doc: RNAs - predict, cluster, identify, annotate

requirements:
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
    - class: ScatterFeatureRequirement
    - class: MultipleInputFeatureRequirement

inputs:
    jobid: string
    sequences: File
    # static DBs
    m5rnaBDB: File
    m5rnaFull: File
    m5rnaClust: File
    m5rnaIndex: Directory
    m5rnaPrefix: string

outputs:
    rnaFeatureOut:
        type: File
        outputSource: rnaFeature/output
    rnaClustSeqOut:
        type: File
        outputSource: rnaCluster/outSeq
    rnaClustMapOut:
        type: File
        outputSource: formatCluster/output
    rnaSimsOut:
        type: File
        outputSource: bleachSims/output
    rnaFilterOut:
        type: File
        outputSource: annotateSims/outFilter
    rnaExpandOut:
        type: File
        outputSource: annotateSims/outRna
    rnaLCAOut:
        type: File
        outputSource: annotateSims/outLca

steps:
    sortmerna:
        run: ../Tools/sortmerna.tool.cwl
        in:
            input: sequences
            refFasta: m5rnaClust
            indexDir: m5rnaIndex
            indexName: m5rnaIndex
        out: output
    sortseq:
        run: ../Tools/seqUtil.tool.cwl
        in:
            sequences: sequences
            sortbyid2tab:
                default: true
            output:
                source: sequences
                valueFrom: $(self).sort.tab
        out: file
    sorttab:
        run: ../Tools/sort.tool.cwl
        in:
            input: sortmerna/output
            key: ["1,1"]
            outName:
                source: sortmerna/output
                valueFrom: $(self).sort
        out: output
    rnaFeature:
        run: ../Tools/rna_feature.tool.cwl
        in:
            sequence: sortseq/file
            aligned: sorttab/output
            outName:
                source: jobid
                valueFrom: $(self).425.search.rna.fna
        out: output
    rnaCluster:
        run: ../Tools/cdhit-est.tool.cel
        in:
            input: rnaFeature/output
            identity: 0.97
            outName:
                source: jobid
                valueFrom: $(self).440.cluster.rna.97.fna
        out: [outSeq, outClstr]
    formatCluster:
        run: ../Tools/format_cluster.tool.cwl
        in:
            input: rnaCluster/outClstr
            outName:
                source: jobid
                valueFrom: $(self).440.cluster.rna.97.mapping
        out: output
    rnaBlat:
        run: ../Tools/blat.tool.cwl
        in:
            query: rnaCluster/outSeq
            database: m5rnaFull
            dbType: dna
            queryType: rna
            fastMap:
                default: true
            outName:
                source: jobid
                valueFrom: $(self).450.rna.sims.full
        out: output
    bleachSims:
        run: ../Tools/bleachsims.tool.cwl
        in:
            input: rnaBlat/output
            outName:
                source: jobid
                valueFrom: $(self).450.rna.sims
        out: output
    annotateSims:
        run: ../Tools/sims_annotate.tool.cwl
        in:
            input: bleachSims/output
            database: m5rnaBDB
            outFilterName:
                source: jobid
                valueFrom: $(self).450.rna.sims.filter
            outRnaName:
                source: jobid
                valueFrom: $(self).450.rna.expand.rna
            outLcaName:
                source: jobid
                valueFrom: $(self).450.rna.expand.lca
        out: [outFilter, outRna, outLca]

