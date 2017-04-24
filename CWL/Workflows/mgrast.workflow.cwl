cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement
  - class: StepInputExpressionRequirement

inputs:
  jobid : int
  mgid: string
  api_url: string
  api_key: string?
  no-shock:
    type: boolean?
    default: true
  
  # Predata  
  db_dir: Directory
  nr_dir: Directory
  nr_prefix: string
  nr_version: string
  nr_part_1: File
  nr_part_2: File
  nr_aa_annotation_version: string
  nr_aa_sequence_version: string
  nr_aa_ann_file: File
  nr_rna_annotation_version: string
  nr_rna_sequence_version: string
  nr_rna_ann_file: File
  nr_taxa_hierarchy: File
  nr_ontology_hierachy: File
       
  # Parameters  
  sequences: File
  seqformat: string
  sequencing_method: 
    type: string
    doc: <sanger|454|illumina|complete>
    default: illumina
  qc_proc:  
    type: int?
    default: 8
  qc_kmers: 
    type: string?
    default: 6,15
  assembled: int
  filter_options: string?
  dereplicate: int
  derep_prefix_length: int
  derep_memory:
    type: int?
    default: 10  
  screen_index: string
  screen_bowtie: int
  rna:
    type: boolean?
    default: true
  rna_nr_clust: File  
  rna_nr: File
  rna_nr_version: string
  rna_pid: int
  rna_assembled: boolean
  rna_clust_memory:
    type: int
    default: 20
   
  memory_index_sims: int  
    
  ff_memory:
    type: int?
    default: 8
  ff_overlap:
    type: int?
    default: 10  
  # aa cluster  
  aa_cluster_memory:
    type: int?
    default: 20 
  aa_cluster_pid: 
     type: int?
     default: 90
     
  
    

outputs:
  # qc
  qcPassedFile:
    type: File
    outputSource: preprocess/passed
  qcRemovedFile: 
    type: File
    outputSource: preprocess/removed 
  # dereplicate - screen
  derepAttr:
    type: File[]
    outputSource: dereplication/attributes  
  screenPassedFile:
    type: File
    outputSource: screen/passed
  screenPassedAttr:
    type: File    
    outputSource: screen/passedAttr   
  # rna
  rnaFile:
    type: File
    outputSource: searchRNA/rna
  rnaClusterFile:
    type: File
    outputSource: clusterRNA/fasta
  rnaMappingFile:
    type: File
    outputSource: clusterRNA/mapping
  rnaSimsFile:
    type: File
    outputSource: simsRNA/sims
  # AA
  simsAAFile:
    type: File
    outputSource: simsAA/sims
  clusterAAFile:
    type: File
    outputSource: clusterAA/fasta
  clusterMappingFile:
    type: File
    outputSource: clusterAA/mapping
  filterRNAFile:
    type: File
    outputSource: filterRNA/filtered
  genecallsFaaFile:
    type: File
    outputSource: genecalling/faa 
  genecallsFnaFile:
    type: File
    outputSource: genecalling/fna
  # annotate  
  proteinFilterFile:
    type: File
    outputSource: annotateAA/filter
  proteinFile:
    type: File
    outputSource: annotateAA/protein  
  proteinLcaFile:
   type: File
   outputSource: annotateAA/lca
  proteinOntologyFile:
   type: File
   outputSource: annotateAA/ontology
  rnaFilterFile:
   type: File
   outputSource: annotateRNA/filter
  rnaLcaFile:
    type: File
    outputSource: annotateRNA/lca
  rnaFeatureFile:
    type: File
    outputSource: annotateRNA/feature
  indexedSimsFile:
    type: File
    outputSource: indexSims/index  
           

steps:
  qc:
    run: ../Tools/awe_qc.tool.yaml
    in:
      seqfile: sequences
      format: seqformat
      out_prefix:
        source: jobid
        valueFrom: $(self).075
      proc: qc_proc
      filter_options: filter_options
       
    out: [assembly,qcstats,uploadstats]

  preprocess:
    # run: awe_preprocess.tool.yaml
    run: ../Tools/awe_preprocess.tool.yaml
    requirements:
      - class: EnvVarRequirement
      # No option to mask/mark env virables as private
      # private env variables are not supposed to show up in a completed job/workflow/recipe document  
        envDef:
          MGRAST_WEBKEY: api_key
    in:
      input: sequences
      format: seqformat
      out_prefix:
        source: jobid
        valueFrom: $(self).100.preprocess
      filter_options: filter_options
      no-shock: no-shock
    out: [removed,passed]
 
 
  # dereplicate-screen
  dereplication:
    run: ../Tools/awe_dereplicate.tool.yaml 
    requirements:
      - class: InitialWorkDirRequirement
        listing:
          - entryname: userattr.json
            entry: |
                    {
                      "stage_id": "150",
                      "stage_name": "dereplication workflow",
                      "file_format": "fasta",
                      "seq_format": "bp"
                    } 
    in:      
      input: preprocess/passed 
      out_prefix:
        source: jobid
        valueFrom: $(self).150.dereplication
      prefix_length: derep_prefix_length 
      dereplicate: dereplicate
      memory: derep_memory
      no-shock: no-shock
    out: [passed , removed , attributes]
    
  screen:
    run: ../Tools/awe_bowtie_screen.tool.yaml
    requirements:
      - class: InitialWorkDirRequirement
        listing:
          - entryname: userattr.json
            entry: |
                    {
                      "stage_id": "299",
                      "stage_name": "screen",
                      "data_type": "sequence",
                      "file_format": "fasta",
                      "seq_format": "bp"
                    }
    in:
      input: dereplication/passed
      index: screen_index
      indexDir: db_dir 
      bowtie:  screen_bowtie
      proc: qc_proc
      no-shock: no-shock
      output:
        source: jobid
        valueFrom: $(self).299.screen.passed.fna 
      
     
    out: [passed , passedAttr]
    
    
  # RNA
  searchRNA:
    run: ../Tools/awe_search_rna.tool.yaml
    in:
      input: preprocess/passed
      output:
        source: jobid
        valueFrom: $(self).425.search.rna.fna
      rna_nr: rna_nr_clust

    out: [rna]

  clusterRNA:
    run: ../Tools/awe_cluster.tool.yaml
    in:
      input: searchRNA/rna
      out_prefix:
        source: jobid
        valueFrom: $(self).440.cluster
      pid: rna_pid
      memory: rna_clust_memory
      no-shock: no-shock
      exclusive_parameters:
        valueFrom: |
            ${ return { "rna": true }; }

    out: [fasta,mapping]

  simsRNA:
    run: ../Tools/awe_blat_rna.tool.yaml
    in:
      input: clusterRNA/fasta
      output:
        source: jobid
        valueFrom: $(self).450.rna.sims
      rna_nr: rna_nr
      rna_nr_version: rna_nr_version
      assembled: rna_assembled
    out: [sims]
    
  # AA
  genecalling:
    run: ../Tools/awe_genecalling.tool.yaml
    in:
      input: screen/passed
      out_prefix: 
        source: jobid
        valueFrom: $(self).350.genecalling.coding
      type: sequencing_method
      # Using defaults:
      # size: 100
      # proc: 8 
               
    out: [fna,faa]

  filterRNA:
    run: ../Tools/awe_filter_feature.tool.yaml
    in:
      in_clust: clusterRNA/mapping
      in_sim: simsRNA/sims
      in_seq: genecalling/faa
      output: 
        source: jobid
        valueFrom: $(self).375.filtering.faa
      memory: ff_memory
      overlap: ff_overlap
      no-shock: no-shock
    out: [filtered]
    
  clusterAA:
    run: ../Tools/awe_cluster_aa.tool.yaml     
    in:      
      input: filterRNA/filtered 
      out_prefix:
        source: jobid
        valueFrom: $(self).550.cluster
      pid: aa_cluster_pid
      memory: aa_cluster_memory
    out: [fasta , mapping]
  
  simsAA:
    run: ../Tools/awe_blat_protein.tool.yaml
    in:
      input: clusterAA/fasta
      output: 
        source: jobid
        valueFrom: $(self).650.superblat.sims
      nr_dir: nr_dir  
      nr_prefix:  nr_prefix
      nr_part_1: nr_part_1
      nr_part_2: nr_part_2
      nr_version: nr_version
       
    out: [sims]
    
  # annotate
  annotateAA:
    run: ../Tools/awe_annotate_aa_sims.tool.yaml
    in:
      input: simsAA/sims
      out_prefix: 
        source: jobid
        valueFrom: $(self).650
      ach_ver: nr_aa_annotation_version 
      ach_sequence_ver: nr_aa_sequence_version 
      ann_file: nr_aa_ann_file
      exclusive_parameters: 
        # source: nr_prefix
        valueFrom: |
            ${ return { "aa": true }; }  
                          
    out: [filter,protein,lca,ontology]

  annotateRNA:
    run: ../Tools/awe_annotate_rna_sims.tool.yaml
    in:
      input: simsRNA/sims
      out_prefix: 
        source: jobid
        valueFrom: $(self).450
      ach_ver: nr_rna_annotation_version 
      ach_sequence_ver: nr_rna_sequence_version 
      ann_file: nr_rna_ann_file 
    out: [filter, feature, lca]    
    
  indexSims:
    run: ../Tools/awe_index_sim_seq.tool.yaml
    requirements:
      - class: EnvVarRequirement
      # No option to mask/mark env virables as private
      # private env variables are not supposed to show up in a completed job/workflow/recipe document
        envDef:
          MGRAST_WEBKEY: api_key
    in:
      in_seqs: [ genecalling/fna    , searchRNA/rna       ]
      in_maps: [ clusterAA/mapping  , clusterRNA/mapping  ]
      in_sims: [ annotateRNA/filter , annotateAA/filter   ]
      memory: memory_index_sims
      m5nr_version: nr_aa_annotation_version
      output:
        source: jobid
        valueFrom: $(self).700.annotation.sims.filter.seq
    out: [index]    


  summaryMD5:
    label: md5 abundance
    run: ../Tools/awe_annotate_summary.tool.yaml
    in:
      in_expand: [ annotateAA/filter , annotateRNA/filter ]
      in_maps: [ clusterAA/mapping  , clusterRNA/mapping  ]
      in_assemb: qc/assembly
      in_index: indexSims/index
      abundanceType: 
        default: "md5"
      nr_version: nr_aa_annotation_version
      output:
        source: jobid
        valueFrom: $(self).700.annotation.md5.abundance 
    out: [abundance]
                         
  summaryLCA:
    label: lca abundance
    run: ../Tools/awe_annotate_summary.tool.yaml
    # -in_expand=@[% job_id %].650.aa.expand.lca 
    # -in_expand=@[% job_id %].450.rna.expand.lca
    # -in_maps=@[% job_id %].550.cluster.aa[% aa_pid %].mapping 
    # -in_maps=@[% job_id %].440.cluster.rna[% rna_pid %].mapping
    # -in_assemb=@[% job_id %].075.assembly.coverage 
    # -output=[% job_id %].700.annotation.lca.abundance 
    # -type=lca",
    
    in:
      in_expand: [ annotateAA/lca , annotateRNA/lca ]
      in_maps: [ clusterAA/mapping  , clusterRNA/mapping  ]
      in_assemb: qc/assembly
      abundanceType: 
        default: "lca"
      nr_version: nr_aa_annotation_version
      output:
        source: jobid
        valueFrom: $(self).700.annotation.lca.abundance 
    out: [abundance]  
      
  summarySource:
    label: source abundance
    run: ../Tools/awe_annotate_summary.tool.yaml
    # -in_expand=@[% job_id %].650.aa.expand.protein 
    # -in_expand=@[% job_id %].450.rna.expand.rna 
    # -in_maps=@[% job_id %].550.cluster.aa[% aa_pid %].mapping 
    # -in_maps=@[% job_id %].440.cluster.rna[% rna_pid %].mapping 
    # -in_assemb=@[% job_id %].075.assembly.coverage 
    # -output=[% job_id %].700.annotation.source.stats 
    # -type=source",
    
    in:
      in_expand: [ annotateAA/protein , annotateRNA/feature ]
      in_maps: [ clusterAA/mapping  , clusterRNA/mapping  ]
      in_assemb: qc/assembly
      abundanceType: 
        default: "source"
      nr_version: nr_aa_annotation_version
      output:
        source: jobid
        valueFrom: $(self).700.annotation.source.stats 
    out: [abundance]
    
  loadCass:
    label: abundance cassandra load
    run: ../Tools/awe_load_cass.tool.yaml
    requirements:
      - class: InitialWorkDirRequirement
        listing:
          - entryname: userattr.json
            entry: |
                {
                  "id": "$(inputs.mgid)"
                }
    
    in:
      mgid: mgid
      job: jobid
      api_url: api_url
      api_key: api_key
      ann_ver: nr_aa_annotation_version
      md5: summaryMD5/abundance
      lca: summaryLCA/abundance
    out: [log, error]


  finalStats:
    label: done stage
    run: ../Tools/awe_stats.tool.yaml
    # -job=[% job_id %] 
    # -nr_ver=[% ach_sequence_ver %] 
    # -ann_ver=[% ach_annotation_ver %] 
    # -api_url=[% mgrast_api %] 
    # -upload=@[% job_id %].075.upload.stats 
    # -qc=@[% job_id %].075.qc.stats 
    # -preproc=@[% job_id %].100.preprocess.passed.fna 
    # -derep=@[% job_id %].150.dereplication.removed.fna 
    # -post_qc=@[% job_id %].299.screen.passed.fna 
    # -source=@[% job_id %].700.annotation.source.stats 
    # -search=@[% job_id %].425.search.rna.fna 
    # -rna_clust=@[% job_id %].440.cluster.rna[% rna_pid %].fna 
    # -rna_map=@[% job_id %].440.cluster.rna[% rna_pid %].mapping 
    # -genecall=@[% job_id %].350.genecalling.coding.faa 
    # -aa_clust=@[% job_id %].550.cluster.aa[% aa_pid %].faa 
    # -aa_map=@[% job_id %].550.cluster.aa[% aa_pid %].mapping 
    # -ontol=[% job_id %].650.aa.expand.ontology 
    # -filter=[% job_id %].700.annotation.sims.filter.seq 
    # -md5_abund=@[% job_id %].700.annotation.md5.abundance
    # -m5nr_db=m5nr_v1.annotation.bdb 
    # -taxa_hier=m5nr_v1.taxonomy.map.json 
    # -ont_hier=m5nr_v1.ontology.map.json",
    
    in:
      job: jobid
      nr_ver: nr_aa_sequence_version
      ann_ver: nr_aa_annotation_version
      api_url: api_url
      # file inputs, replace with step inputs in combined workflow
      upload: qc/uploadstats
      qc: qc/qcstats
      preproc: preprocess/passed
      derep: dereplication/removed
      post_qc: screen/passed
      source: summarySource/abundance
      search: searchRNA/rna
      rna_clust: clusterRNA/fasta
      rna_map: clusterRNA/mapping
      genecall: genecalling/faa
      aa_clust: clusterAA/fasta
      aa_map: clusterAA/mapping
      ontol: annotateAA/ontology
      # step input within this workflow
      filter: indexSims/index 
      #aa/filter
      md5_abund: summaryMD5/abundance
      # DB/Predata 
      m5nr_db: nr_aa_ann_file
      taxa_hier: nr_taxa_hierarchy
      ont_hier: nr_ontology_hierachy    
      
    out: [
            statisticsFile ,
            statisticsAttr ,
            screenFile ,
            screenAttr ,
            searchFile ,
            searchAttr ,
            rnaClustFile ,
            rnaClustAttr ,
            rnaMapFile ,
            rnaMapAttr ,
            genecallFile ,
            genecallAttr ,
            aaClustFile ,
            aaClustAttr ,
            aaMapFile ,
            aaMapAttr
    ]
    
