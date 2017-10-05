cwlVersion: v1.0
class: Workflow

label: index sim seq
doc: create sorted / filtered similarity file with feature sequences, and index by md5

requirements:
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
    - class: ScatterFeatureRequirement
    - class: MultipleInputFeatureRequirement

inputs:
    jobid: string
    featureSeqs: File[]
    filterSims: File[]
    clustMaps: File[]

outputs:
    simSeqOut:
        type: File
        outputSource: sortSimSeq/output
    indexOut:
        type: File
        outputSource: indexSimSeq/output

steps:
    unclusterSims:
        run: ../Tools/uncluster_sims.tool.cwl
        in:
            simHit: filterSims
            clustMap: clustMap
            outName:
                source: jobid
                valueFrom: $(self).uncluster.sims
        out: [output]
    sortSims:
        run: ../Tools/sort.tool.cwl
        in:
            input: unclusterSims/output
            key: 
                valueFrom: "1,1"
            outName:
                source: unclusterSims/output
                valueFrom: $(self.basename).sort
        out: [output]
    catSeqs:
        run: ../Tools/cat.tool.cwl
        in:
            files: featureSeqs
            outName:
                source: jobid
                valueFrom: $(self).feature.seqs
        out: [output]
    sortSeqs:
        run: ../Tools/seqUtil.tool.cwl
        in:
            sequences: catSeqs/output
            sortbyid2tab:
                default: true
            output:
                source: catSeqs/output
                valueFrom: $(self.basename).sort.tab
        out: [file]
    addSeq2Sim:
        run: ../Tools/add_seq2sims.tool.cwl
        in:
            sequences: sortSeqs/file
            similarity: sortSims/output
            outName:
                source: sortSims/output
                valueFrom: $(self.basename).seq
        out: [output]
    sortSimSeq:
        run: ../Tools/sort.tool.cwl
        in:
            input: addSeq2Sim/output
            key: 
                valueFrom: "2,2"
            outName:
                source: jobid
                valueFrom: $(self).700.annotation.sims.filter.seq
        out: [output]
    indexSimSeq:
        run: ../Tools/index_sims_file_md5.tool.cwl
        in:
            input: sortByMd5/output
            outName:
                source: sortByMd5/output
                valueFrom: $(self.basename).index
        out: [output]

