cwlVersion: v1.0
class: Workflow

label: protein similarities
doc: run diamond on mutlple DBs and merge-sort results

requirements:
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
    - class: ScatterFeatureRequirement
    - class: MultipleInputFeatureRequirement

inputs:
    jobid: string
    sequences: File
    # static DBs
    m5nrFull: File[]

outputs:
    protSimsOut:
        type: File
        outputSource: bleachSims/output

steps:
    diamond:
        run: ../Tools/diamond.tool.cwl
        scatter: ["#diamond/database", "#diamond/outName"]
        scatterMethod: dotproduct
        in:
            query: sequences
            database: m5nrFull
            outName:
                source: m5nrFull
                valueFrom: $(self.basename).diamond.sims
        out: [output]
    mergeSims:
        run: ../Tools/sort.tool.cwl
        in:
            input: diamond/output
            key:
                valueFrom: $(["1,1", "12,12nr", "3,3nr"])
            merge:
                default: true
            outName:
                source: jobid
                valueFrom: $(self).diamond.sims.merge
        out: [output]
    bleachSims:
        run: ../Tools/bleachsims.tool.cwl
        in:
            input: mergeSims/output
            minHitOnly:
                default: true
            outName:
                source: jobid
                valueFrom: $(self).650.diamond.sims
        out: [output]

