cwlVersion: v1.0
class: Workflow

label: abundance
doc: abundace profiles from annotated files, for protein and/or rna

requirements:
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
    - class: ScatterFeatureRequirement
    - class: MultipleInputFeatureRequirement
    - class: SubworkflowFeatureRequirement

inputs:
    jobid: string
    md5index: File
    filterSims: File[]
    expandSims: File[]
    rnaExpandLca: File
    protExpandLca: File
    rnaClustMap: File
    protClustMap: File
    m5nrSCG: File
    coverage: File?

outputs:
    md5ProfileOut:
        type: File
        outputSource: md5Profile/output
    lcaProfileOut:
        type: File
        outputSource: lcaProfile/contigLCA
    sourceStatsOut:
        type: File
        outputSource: sourceStats/output

steps:
    md5Profile:
        run: ../Tools/sims_abundance.tool.cwl
        in:
            input: filterSims
            cluster:
                source:
                    - rnaClustMap
                    - protClustMap
            coverage: coverage
            md5index: md5index
            profileType: 
                valueFrom: md5
            outName:
                source: jobid
                valueFrom: $(self).700.annotation.md5.abundance
        out: [output]
    lcaProfile:
        run: ../Workflows/contig-lca.workflow.cwl
        in:
            jobid: string
            rnaExpandLca: rnaExpandLca
            protExpandLca: protExpandLca
            rnaClustMap: rnaClustMap
            protClustMap: protClustMap
            m5nrSCG: m5nrSCG
            coverage: coverage
        out: [contigLCA]
    sourceStats:
        run: ../Tools/sims_abundance.tool.cwl
        in:
            input: expandSims
            cluster:
                source:
                    - rnaClustMap
                    - protClustMap
            coverage: coverage
            profileType: 
                valueFrom: source
            outName:
                source: jobid
                valueFrom: $(self).700.annotation.source.stats
        out: [output]

