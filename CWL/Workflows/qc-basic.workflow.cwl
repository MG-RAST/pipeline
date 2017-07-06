cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  jobid: string
  sequences: File
  
  kmerLength: 
    type: 
      type: array
      items: int
    default: [6]
  basepairs: int
    
    

outputs:
  consensusStatsFile:
    type: File
    outputSource: consensus/consensus
  sequenceStatsFile:
    type: File
    outputSource: sequenceStats/stats
  sequenceStatsLenFile:
    type: File
    outputSource: sequenceStats/len_bin
  sequenceStatsGcFile:
    type: File
    outputSource: sequenceStats/gc_bin    
  driseeFile:
    type: File
    outputSource: drisee/info
  driseeStatsFile:
    type: File
    outputSource: drisee/stats  
  kmerFile:
    type: 
      type: array
      items: File
    outputSource: [kmer/stats]
  consensusFile:
    type: File
    outputSource: consensus/consensus
  formatSeqStatsFile:
    type: File
    outputSource: formatSequenceStats/stats
  formatSeqStatsBinFile:
    type: File
    outputSource: formatSequenceStats/bins

steps:
  
  sequenceStats:
    run: ../Tools/seq_length_stats.tool.cwl
    in:
      sequences: sequences
      output:
        source: jobid
        valueFrom: $(self).100.preprocess.length.stats
      length_bin:
        source: jobid
        valueFrom: $(self).100.preprocess.length.bin
      gc_percent_bin:
        source: jobid
        valueFrom: $(self).100.preprocess.gc.bin
    out: [stats , len_bin , gc_bin]    
  
  drisee:
    run: ../Tools/drisee.tool.cwl
    in:
      sequences: sequences

    out: [ info , error , stats ]


  # Compute kmer for first value in list
  kmer:
    run: ../Tools/kmer-tool.tool.cwl
    
    scatter: "#kmer/length"  
    in:
      sequences: sequences
      length: 
        source: kmerLength
#         valueFrom: $(self[0])
      prefix:
        source: jobid
        valueFrom: $(self).100.preprocess

    out: [ summary, error , stats ]

  consensus:
    run: ../Tools/consensus.tool.cwl
    in:
      sequences: sequences
      stats: sequenceStats/stats
      output:
        source: jobid
        valueFrom: $(self).100.preprocess.consensus.stats

    out: [summary, error , consensus]


  formatSequenceStats:
    run: ../Tools/format_seq_stats.tool.cwl
    in:
      output_prefix:
        source: jobid
        valueFrom: $(self).100.preprocess
      sequence_stats: sequenceStats/stats
      sequence_lengths: sequenceStats/len_bin
      sequence_gc: sequenceStats/gc_bin
    out: [stats, bins]




  # formatQcStats:
  #   run: ../Tools/format_qc_stats.tool.cwl
  #   in:
  #     output_prefix:
  #       source: jobid
  #       valueFrom: $(self).100.preprocess
  #     drisee_stat: drisee/stats
  #     drisee_info: drisee/info
  #     kmer_lens:
  #       source: kmerLength
  #       valueFrom: |
  #         ${
  #           return self.join()
  #         }
  #     kmer_stats:
  #       source: [kmer/stats]
  #       valueFrom: |
  #         ${
  #           return self.map(
  #               function(myFile){ return myFile.path }
  #           ).join();
  #         }
  #     consensus: consensus/consensus
  #   out: [stats, summary]
