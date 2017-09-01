cwlVersion: v1.0
class: Workflow

label: rna abundance
doc: RNAs - abundace profiles from annotated files

requirements:
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
    - class: ScatterFeatureRequirement
    - class: MultipleInputFeatureRequirement

inputs:
    jobid: string
    rnaExpand: File
    rnaLCA: File
    rnaClustMap: File
    coverageStats: File

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
            input: rnaExpand
            cluster: rnaClustMap
            coverage: coverageStats
            profileType: 
              default: md5
            outName: # change to outName
                source: jobid
                valueFrom: $(self).700.annotation.md5.abundance
        out: [output]
    lcaProfile:
        run: ../Tools/sims_abundance.tool.cwl
        in:
            input: rnaLCA
            cluster: rnaClustMap
            coverage: coverageStats
            profileType: 
              default: lca
            outName:
                source: jobid
                valueFrom: $(self).700.annotation.lca.abundance
        out: [output]
    sourceStats:
        run: ../Tools/sims_abundance.tool.cwl
        in:
            input: rnaExpand
            cluster: rnaClustMap
            coverage: coverageStats
            profileType: 
              default: source
            outName:
                source: jobid
                valueFrom: $(self).700.annotation.source.stats
        out: [output]

