cwlVersion: v1.0
class: CommandLineTool

label: annotate sims
doc: |
    create expanded annotated sims files from input md5 sim file and m5nr db
    sims_annotate.pl --verbose --in_sim <input> --in_scg <scgs> --ann_file <database> --format <seqFormat> --out_filter <outFilter> --out_expand <outExpand> -out_lca <outLca> --frag_num 5000

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
    
    scgs:
        type: File?
        doc: md5 single copy gene file
        format:
            - Formats:json
        inputBinding:
            prefix: --in_scg
    
    database:
        type: File
        doc: BerkelyDB of condensed M5NR 
        inputBinding:
            prefix: --ann_file
    
    seqFormat:
        type: string
        doc: Type of sequences data in input file, rna or protein
        default: protein
        inputBinding:
            prefix: --format
    
    outFilterName:
        type: string
        doc: Output filtered sim file
        inputBinding:
            prefix: --out_filter
    
    outExpandName:
        type: string
        doc: Output expanded protein sim file (protein mode only)
        inputBinding:
            prefix: --out_expand
    
    outLcaName:
        type: string
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
            glob: $(inputs.outFilterName)
    outExpand:
        type: File
        doc: Output expanded sim file
        outputBinding: 
            glob: $(inputs.outExpandName)
    outLca:
        type: File
        doc: Output expanded LCA file
        outputBinding: 
            glob: $(inputs.outLcaName)

$namespaces:
    Formats: FileFormats.cv.yaml

