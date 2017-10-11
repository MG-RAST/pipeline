cwlVersion: v1.0
class: Workflow

label: abundance
doc: abundace profiles from annotated files, for protein and/or rna

requirements:
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
    - class: ScatterFeatureRequirement
    - class: MultipleInputFeatureRequirement

inputs:
    jobid: string
    md5index: File
    filterSims: File[]
    expandSims: File[]
    lcaAnns: File[]
    clustMaps: File[]
    coverage:
        type: File
        default: 'null'

outputs:
    md5ProfileOut:
        type: File
        outputSource: md5Profile/output
    lcaProfileOut:
        type: File
        outputSource: lcaProfile/output
    sourceStatsOut:
        type: File
        outputSource: sourceStats/output

steps:
    md5Profile:
        run: ../Tools/sims_abundance.tool.cwl
        in:
            input: filterSims
            cluster: clustMaps
            coverage: coverage
            md5index: md5index
            profileType: 
                valueFrom: md5
            outName:
                source: jobid
                valueFrom: $(self).700.annotation.md5.abundance
        out: [output]
    lcaProfile:
        run: ../Tools/sims_abundance.tool.cwl
        in:
            input: lcaAnns
            cluster: clustMaps
            coverage: coverage
            profileType: 
                valueFrom: lca
            outName:
                source: jobid
                valueFrom: $(self).700.annotation.lca.abundance
        out: [output]
    sourceStats:
        run: ../Tools/sims_abundance.tool.cwl
        in:
            input: expandSims
            cluster: clustMaps
            coverage: coverage
            profileType: 
                valueFrom: source
            outName:
                source: jobid
                valueFrom: $(self).700.annotation.source.stats
        out: [output]

