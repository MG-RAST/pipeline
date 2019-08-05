cwlVersion: v1.0
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: mgrast/pipeline:4.03
  
stdout: format_seq_stats.stats
stderr: format_seq_stats.error

inputs:
  sequence_stats:
    doc: stats tabbed file
    type: File
    inputBinding:
      prefix: -seq_stat
  
  sequence_lengths:
    type: File
    doc: len bin file
    inputBinding:
      prefix: -seq_lens
      
  sequence_gc:
    type: File
    doc: gc bin file
    inputBinding:
      prefix: -seq_gc
      
  output_prefix:
    type: string
    doc: output prefix, e.g. ${output_prefix}.seq.bins, ${output_prefix}.seq.stats
    inputBinding: 
      prefix: -out_prefix
                    
baseCommand: [format_seq_stats.pl]

outputs:
  stats:
    type: File
    outputBinding:
      glob: $(inputs.output_prefix).seq.stats
    
  error: 
    type: stderr  
  bins:
    type: File
    outputBinding:
      glob: $(inputs.output_prefix).seq.bins

