cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement

inputs:
  jobid: string
  sequences: File
  
  kmerLength: 
    type: int?
    default: 6
  basepairs: int
    
    

outputs:
  sequenceStatsFile:
    type: File
    outputSource: sequenceStats/stats
  sequenceStatsLenFile:
    type: File
    outputSource: sequenceStats/len_bin
  sequenceStatsGcFile:
    type: File
    outputSource: sequenceStats/gc_bin    
  # driseeFile:
  #   type: File
  #   outputSource: drisee/info
  kmerFile: 
    type: File
    outputSource: kmer/stats
  consensusFile:
    type: File
    outputSource: consensus/consensus  
  

steps:
  
  sequenceStats:
    run: ../Tools/seq_length_stats.tool.cwl
    in:
      sequences: sequences
      length_bin:
        source: jobid
        valueFrom: $(self).100.preprocess.length.bin
      gc_percent_bin:
        source: jobid
        valueFrom: $(self).100.preprocess.gc.bin
    out: [stats , len_bin , gc_bin]    
  
  # drisee:
  #   run: ../Tools/drisee.tool.cwl
  #   in:
  #     sequences: sequences
  #
  #   out: [ info , error , stats ]
   

  kmer:
    run: ../Tools/kmer-tool.tool.cwl
    in:
      
      sequences: sequences
      length: kmerLength
      prefix:
        source: jobid
        valueFrom: $(self).100.preprocess
      
    out: [summary, error , stats]
    
  consensus:
    run: ../Tools/consensus.tool.cwl 
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
      sequences: sequences
      stats: sequenceStats/stats
      output:
        source: jobid
        valueFrom: $(self).100.preprocess 
     
    out: [summary, error , consensus]
       
  # qc_stats:
 #    run: ../Tools/qc_stats.tool.cwl
 #    in:
 #      seqStats: sequenceStats/stats
 #    out:
 #      stats: [stats]
