cwlVersion: v1.0
class: Workflow

label: contig LCA
doc: |
    create LCA consistant across input contigs contigs
    order of precedence - rRNA, single copy gene, LCA of genes

requirements:
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
    - class: ScatterFeatureRequirement
    - class: MultipleInputFeatureRequirement

inputs:
    jobid: string
    rnaClustMap: File
    rnaExpandLca: File
    protClustMap: File
    protExpandLca: File
    coverage: File?

outputs:
    contigLCA:
        type: File
        outputSource: abundanceLca/output

steps:
    unclusterRna:
        run: ../Tools/uncluster_sims.tool.cwl
        in:
            simHit: rnaExpandLca
            clustMap: rnaClustMap
            position:
                valueFrom: "2"
            outName:
                source: rnaExpandLca
                valueFrom: $(self.basename).uncluster
        out: [output]
    sortRna:
        run: ../Tools/sort.tool.cwl
        in:
            input: unclusterRna/output
            key: 
                valueFrom: "2,2"
            outName:
                source: unclusterRna/output
                valueFrom: $(self.basename).sort
        out: [output]
    unclusterProt:
        run: ../Tools/uncluster_sims.tool.cwl
        in:
            simHit: protExpandLca
            clustMap: protClustMap
            position:
                valueFrom: "2"
            outName:
                source: protExpandLca
                valueFrom: $(self.basename).uncluster
        out: [output]
    sortProt:
        run: ../Tools/sort.tool.cwl
        in:
            input: unclusterProt/output
            key: 
                valueFrom: "2,2"
            outName:
                source: unclusterProt/output
                valueFrom: $(self.basename).sort
        out: [output]
    expandLca:
        run: ../Tools/find_contig_lca.tool.cwl
        in:
            inRna: sortRna/output
            inProt: sortProt/output
            outName:
                source: jobid
                valueFrom: $(self).650.contig.expand.lca
        out: [output]
    abundanceLca:
        run: ../Tools/sims_abundance.tool.cwl
        in:
            input:
                source: expandLca/output
                valueFrom: ${ return [self]; }
            cluster:
                source:
                    - rnaClustMap
                    - protClustMap
            coverage: coverage
            profileType: 
                valueFrom: lca
            outName:
                source: jobid
                valueFrom: $(self).700.contig.lca.abundance
        out: [output]
