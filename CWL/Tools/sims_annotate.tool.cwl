cwlVersion: v1.0
class: CommandLineTool

label: annotate sims
doc: |
    create expanded annotated sims files from input md5 sim file and m5nr db
    prot mode: sims_annotate.pl --verbose --in_sim <input> --ann_file <database> --out_filter <outFilter> --out_expand <outExpand> --out_ontology <outOntology> -out_lca <outLca> --frag_num 5000
    rna mode:  sims_annotate.pl --verbose --in_sim <input> --ann_file <database> --out_filter <outFilter> --out_rna <outRna> --out_lca <outLca> --frag_num 5000

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: sims_annotate.log
stderr: sims_annotate.error

inputs:
    input:
        type: File
        doc: Input similarity blast-m8 file
        format:
            - Formats:tsv
        inputBinding:
            prefix: --in_sim
    
    database:
        type: File
        doc: BerkelyDB of condensed M5NR 
        inputBinding:
            prefix: --ann_file
    
    outFilter:
        type: string
        doc: Output filtered sim file
        inputBinding:
            prefix: --out_filter
    
    outExpand:
        type: string?
        doc: Output expanded protein sim file (protein mode only)
        inputBinding:
            prefix: --out_expand
    
    outOntology:
        type: string?
        doc: Output expanded ontology sim file (protein mode only)
        inputBinding:
            prefix: --out_ontology
    
    outRna:
        type: string?
        doc: Output expanded rna sim file (rna mode only)
        inputBinding:
            prefix: --out_rna
    
    outLca:
        type: string?
        doc: Output expanded LCA file (protein and rna mode)
        inputBinding:
            prefix: --out_lca
    
    fragNum:
        type: int?
        doc: Number of fragment chunks to load in memory at once before processing, default 5000
        default: 5000
        inputBinding:
            prefix: --frag_num
    
    verbose:
        type: boolean?
        doc: Verbose logging mode
        inputBinding:
          prefix: --verbose


baseCommand: [sims_annotate.pl]

outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    outFilter:
        type: File
        doc: Output filtered similarity file
        outputBinding: 
            glob: $(inputs.outFilter)
    outExpand:
        type: File?
        doc: Output expanded protein sim file (protein mode only)
        outputBinding: 
            glob: $(inputs.outExpand)
    outOntology:
        type: File?
        doc: Output expanded ontology sim file (protein mode only)
        outputBinding: 
            glob: $(inputs.outOntology)
    outRna:
        type: File?
        doc: Output expanded rna sim file (rna mode only)
        outputBinding: 
            glob: $(inputs.outRna)
    outLca:
        type: File?
        doc: Output expanded LCA file (protein and rna mode)
        outputBinding: 
            glob: $(inputs.outLca)

$namespaces:
    Formats: FileFormats.cv.yaml

