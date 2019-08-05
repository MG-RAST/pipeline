cwlVersion: v1.0
class: CommandLineTool

label: contig LCA
doc: |
    create contig LCA from rRNA and Protein LCAs
    >find_contig_lca.py --rna <rnaLCA> --prot <protLCA> --scg <scgs> --output <outName>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: find_contig_lca.log
stderr: find_contig_lca.error

inputs:
    rnaLCA:
        type: File
        doc: Input expanded rna LCA file
        inputBinding:
            prefix: --rna
    
    protLCA:
        type: File
        doc: Input expanded protein LCA file
        inputBinding:
            prefix: --prot
    
    scgs:
        type: File?
        doc: md5 single copy gene file
        inputBinding:
            prefix: --scg
        
    outName:
        type: string
        doc: Output expanded contig LCA
        inputBinding:
            prefix: --output


baseCommand: [find_contig_lca.py]

arguments:
    - valueFrom: --verbose

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    output:
        type: File
        doc: Output expanded contig LCA file
        outputBinding: 
            glob: $(inputs.outName)

