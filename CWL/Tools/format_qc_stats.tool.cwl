cwlVersion: v1.0
class: CommandLineTool

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: format_qc_stats.stats
stderr: format_qc_stats.error

inputs:
    kmer:
        type:
            type: array
            items:
                type: record
                fields:
                    - name: length
                      type: int
                    - name: file
                      type: File
        doc: kmer record array

    driseeStat:
        type: File?
        doc: drisee stat file
        inputBinding:
            prefix: -drisee_stat

    driseeInfo:
        type: File?
        doc: drisee info file
        inputBinding:
            prefix: -drisee_info
  
    consensus:
        type: File?
        doc: consensus stat file
        inputBinding:
            prefix: -consensus

    coverage:
        type: File?
        doc: coverage stat file
        inputBinding:
            prefix: -coverage

    outPrefix:
        type: string
        doc: output prefix = ${output_prefix}.seq.bins, ${output_prefix}.seq.stats
        inputBinding: 
            prefix: -out_prefix    


baseCommand: [format_qc_stats.pl]

arguments:
    - prefix: -kmer_lens
      valueFrom: |
          ${
              return inputs.kmer.map( 
                  function(r){ return r.length }
              ).join();
          }
    - prefix: -kmer_stats
      valueFrom: |
          ${
              return inputs.kmer.map( 
                  function(r){ return r.file.path }
              ).join();
          }

outputs:
    error: 
        type: stderr
    summary:
        type: File
        outputBinding:
            glob: $(inputs.outPrefix).qc.summary
    stats:
        type: File
        outputBinding:
            glob: $(inputs.outPrefix).qc.stats

