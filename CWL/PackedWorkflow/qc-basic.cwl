{
    "cwlVersion": "v1.0", 
    "$graph": [
        {
            "class": "CommandLineTool", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:4.03", 
                    "class": "DockerRequirement"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "consensus.log", 
            "stderr": "consensus.error", 
            "inputs": [
                {
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "doc": "max number of bps to process [default 100]", 
                    "inputBinding": {
                        "prefix": "--bp_max"
                    }, 
                    "id": "#consensus.tool.cwl/basepairs"
                }, 
                {
                    "type": "string", 
                    "doc": "Output file.", 
                    "inputBinding": {
                        "prefix": "--output"
                    }, 
                    "id": "#consensus.tool.cwl/output"
                }, 
                {
                    "type": "File", 
                    "doc": "Input file, sequence (fasta/fastq).", 
                    "format": [
                        "#consensus.tool.cwl/sequences/FileFormats.cv.yamlfasta", 
                        "#consensus.tool.cwl/sequences/FileFormats.cv.yamlfastq"
                    ], 
                    "inputBinding": {
                        "prefix": "--input"
                    }, 
                    "id": "#consensus.tool.cwl/sequences"
                }, 
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "inputBinding": {
                        "prefix": "--stats"
                    }, 
                    "id": "#consensus.tool.cwl/stats"
                }
            ], 
            "baseCommand": [
                "consensus.py"
            ], 
            "arguments": [
                {
                    "prefix": "--verbose"
                }, 
                {
                    "prefix": "--type", 
                    "valueFrom": "${\n   return inputs.sequences.format.split(\"/\").slice(-1)[0]\n  } \n"
                }
            ], 
            "outputs": [
                {
                    "type": "File", 
                    "outputBinding": {
                        "glob": "$(inputs.output)"
                    }, 
                    "id": "#consensus.tool.cwl/consensus"
                }, 
                {
                    "type": "stderr", 
                    "id": "#consensus.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#consensus.tool.cwl/summary"
                }
            ], 
            "id": "#consensus.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:4.03", 
                    "class": "DockerRequirement"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "drisee.log", 
            "stderr": "drisee.error", 
            "inputs": [
                {
                    "type": "File", 
                    "format": [
                        "#drisee.tool.cwl/sequences/FileFormats.cv.yamlfasta", 
                        "#drisee.tool.cwl/sequences/FileFormats.cv.yamlfastq"
                    ], 
                    "inputBinding": {
                        "position": 1
                    }, 
                    "id": "#drisee.tool.cwl/sequences"
                }
            ], 
            "baseCommand": [
                "drisee"
            ], 
            "arguments": [
                {
                    "valueFrom": "drisee.stats", 
                    "position": 2
                }, 
                "--verbose", 
                "--filter_seq", 
                {
                    "valueFrom": "$(runtime.cores)", 
                    "prefix": "--processes"
                }, 
                {
                    "valueFrom": "$(runtime.tmpdir)", 
                    "prefix": "--tmp_dir"
                }, 
                {
                    "prefix": "--seq_type", 
                    "valueFrom": "${\n   return inputs.sequences.format.split(\"/\").slice(-1)[0]\n  } \n"
                }
            ], 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#drisee.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#drisee.tool.cwl/info"
                }, 
                {
                    "type": "File", 
                    "outputBinding": {
                        "glob": "drisee.stats"
                    }, 
                    "id": "#drisee.tool.cwl/stats"
                }
            ], 
            "id": "#drisee.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:4.03", 
                    "class": "DockerRequirement"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "format_qc_stats.stats", 
            "stderr": "format_qc_stats.error", 
            "inputs": [
                {
                    "type": "File", 
                    "doc": "consensus stat file", 
                    "inputBinding": {
                        "prefix": "-consensus"
                    }, 
                    "id": "#format_qc_stats.tool.cwl/consensus"
                }, 
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "doc": "coverage stat file", 
                    "inputBinding": {
                        "prefix": "-coverage"
                    }, 
                    "id": "#format_qc_stats.tool.cwl/coverage"
                }, 
                {
                    "type": "File", 
                    "doc": "drisee info file", 
                    "inputBinding": {
                        "prefix": "-drisee_info"
                    }, 
                    "id": "#format_qc_stats.tool.cwl/drisee_info"
                }, 
                {
                    "doc": "drisee stat file", 
                    "type": "File", 
                    "inputBinding": {
                        "prefix": "-drisee_stat"
                    }, 
                    "id": "#format_qc_stats.tool.cwl/drisee_stat"
                }, 
                {
                    "type": {
                        "type": "array", 
                        "items": {
                            "type": "record", 
                            "fields": [
                                {
                                    "type": "File", 
                                    "name": "#format_qc_stats.tool.cwl/kmer/file"
                                }, 
                                {
                                    "type": "int", 
                                    "name": "#format_qc_stats.tool.cwl/kmer/length"
                                }
                            ]
                        }
                    }, 
                    "id": "#format_qc_stats.tool.cwl/kmer"
                }, 
                {
                    "type": "string", 
                    "doc": "output prefix = ${output_prefix}.seq.bins, ${output_prefix}.seq.stats", 
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "id": "#format_qc_stats.tool.cwl/output_prefix"
                }
            ], 
            "baseCommand": [
                "format_qc_stats.pl"
            ], 
            "arguments": [
                {
                    "prefix": "-kmer_lens", 
                    "valueFrom": "${\n   return inputs.kmer.map( \n     function(r){ return r.length }\n     ).join() \n  }\n"
                }, 
                {
                    "prefix": "-kmer_stats", 
                    "valueFrom": "${\n   return inputs.kmer.map( \n     function(r){ return r.file.path }\n     ).join() \n  }      \n"
                }
            ], 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#format_qc_stats.tool.cwl/error"
                }, 
                {
                    "type": "File", 
                    "outputBinding": {
                        "glob": "$(inputs.output_prefix).qc.stats"
                    }, 
                    "id": "#format_qc_stats.tool.cwl/stats"
                }, 
                {
                    "type": "File", 
                    "outputBinding": {
                        "glob": "$(inputs.output_prefix).qc.summary"
                    }, 
                    "id": "#format_qc_stats.tool.cwl/summary"
                }
            ], 
            "id": "#format_qc_stats.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:4.03", 
                    "class": "DockerRequirement"
                }
            ], 
            "stdout": "format_seq_stats.stats", 
            "stderr": "format_seq_stats.error", 
            "inputs": [
                {
                    "type": "string", 
                    "doc": "output prefix, e.g. ${output_prefix}.seq.bins, ${output_prefix}.seq.stats", 
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "id": "#format_seq_stats.tool.cwl/output_prefix"
                }, 
                {
                    "type": "File", 
                    "doc": "gc bin file", 
                    "inputBinding": {
                        "prefix": "-seq_gc"
                    }, 
                    "id": "#format_seq_stats.tool.cwl/sequence_gc"
                }, 
                {
                    "type": "File", 
                    "doc": "len bin file", 
                    "inputBinding": {
                        "prefix": "-seq_lens"
                    }, 
                    "id": "#format_seq_stats.tool.cwl/sequence_lengths"
                }, 
                {
                    "doc": "stats tabbed file", 
                    "type": "File", 
                    "inputBinding": {
                        "prefix": "-seq_stat"
                    }, 
                    "id": "#format_seq_stats.tool.cwl/sequence_stats"
                }
            ], 
            "baseCommand": [
                "format_seq_stats.pl"
            ], 
            "outputs": [
                {
                    "type": "File", 
                    "outputBinding": {
                        "glob": "$(inputs.output_prefix).seq.bins"
                    }, 
                    "id": "#format_seq_stats.tool.cwl/bins"
                }, 
                {
                    "type": "stderr", 
                    "id": "#format_seq_stats.tool.cwl/error"
                }, 
                {
                    "type": "File", 
                    "outputBinding": {
                        "glob": "$(inputs.output_prefix).seq.stats"
                    }, 
                    "id": "#format_seq_stats.tool.cwl/stats"
                }
            ], 
            "id": "#format_seq_stats.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:4.03", 
                    "class": "DockerRequirement"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "kmer-tool.log", 
            "stderr": "kmer-tool.error", 
            "inputs": [
                {
                    "type": "int", 
                    "doc": "Length of kmer to use, eg. 6 or 15", 
                    "default": 6, 
                    "inputBinding": {
                        "prefix": "--length"
                    }, 
                    "id": "#kmer-tool.tool.cwl/length"
                }, 
                {
                    "type": "string", 
                    "doc": "Prefix for output file(s)", 
                    "default": "qc", 
                    "id": "#kmer-tool.tool.cwl/prefix"
                }, 
                {
                    "type": "File", 
                    "doc": "Input file, sequence (fasta/fastq) or binary count hash (hash).", 
                    "format": [
                        "Formats:fasta", 
                        "Formats:fastq", 
                        "Formats:hash"
                    ], 
                    "inputBinding": {
                        "prefix": "--input"
                    }, 
                    "id": "#kmer-tool.tool.cwl/sequences"
                }
            ], 
            "baseCommand": [
                "kmer-tool"
            ], 
            "arguments": [
                {
                    "valueFrom": "$(runtime.cores)", 
                    "prefix": "--procs"
                }, 
                {
                    "prefix": "--type", 
                    "valueFrom": "${\n   return inputs.sequences.format.split(\"/\").slice(-1)[0]\n  }\n"
                }, 
                {
                    "prefix": "--format", 
                    "valueFrom": "histo"
                }, 
                "--ranked", 
                {
                    "prefix": "--tmpdir", 
                    "valueFrom": "$(runtime.outdir)"
                }, 
                {
                    "prefix": "--output", 
                    "valueFrom": "$(inputs.prefix).kmer.$(inputs.length).stats"
                }
            ], 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#kmer-tool.tool.cwl/error"
                }, 
                {
                    "type": {
                        "type": "record", 
                        "label": "none", 
                        "fields": [
                            {
                                "name": "#kmer-tool.tool.cwl/stats/length", 
                                "type": "int", 
                                "outputBinding": {
                                    "outputEval": "$(inputs.length)"
                                }
                            }, 
                            {
                                "name": "#kmer-tool.tool.cwl/stats/file", 
                                "type": "File", 
                                "outputBinding": {
                                    "glob": "$(inputs.prefix).kmer.$(inputs.length).stats"
                                }
                            }
                        ]
                    }, 
                    "id": "#kmer-tool.tool.cwl/stats"
                }, 
                {
                    "type": "stdout", 
                    "id": "#kmer-tool.tool.cwl/summary"
                }
            ], 
            "id": "#kmer-tool.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:4.03", 
                    "class": "DockerRequirement"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "seq_length_stats.stats", 
            "stderr": "seq_length_stats.error", 
            "inputs": [
                {
                    "type": "boolean", 
                    "default": false, 
                    "inputBinding": {
                        "prefix": "--fast"
                    }, 
                    "id": "#seq_length_stats.tool.cwl/fast"
                }, 
                {
                    "type": "string", 
                    "doc": "Filename to place gc bins", 
                    "inputBinding": {
                        "prefix": "--gc_percent_bin"
                    }, 
                    "id": "#seq_length_stats.tool.cwl/gc_percent_bin"
                }, 
                {
                    "type": "boolean", 
                    "default": false, 
                    "inputBinding": {
                        "prefix": "--seq_type"
                    }, 
                    "id": "#seq_length_stats.tool.cwl/guess_seq_type"
                }, 
                {
                    "type": "boolean", 
                    "default": false, 
                    "doc": "Ignore commas in header ID", 
                    "inputBinding": {
                        "prefix": "--ignore_comma"
                    }, 
                    "id": "#seq_length_stats.tool.cwl/ignore_comma"
                }, 
                {
                    "type": "string", 
                    "doc": "Filename to place length bins [default is no output]", 
                    "inputBinding": {
                        "prefix": "--length_bin"
                    }, 
                    "id": "#seq_length_stats.tool.cwl/length_bin"
                }, 
                {
                    "type": "string", 
                    "doc": "Output stats file, if not called prints to STDOUT", 
                    "inputBinding": {
                        "prefix": "--output"
                    }, 
                    "id": "#seq_length_stats.tool.cwl/output"
                }, 
                {
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "doc": "max number of seqs to process (for kmer entropy)", 
                    "default": 100000, 
                    "inputBinding": {
                        "prefix": "--seq_max"
                    }, 
                    "id": "#seq_length_stats.tool.cwl/seq_max"
                }, 
                {
                    "type": "File", 
                    "doc": "Input file, sequence (fasta/fastq)", 
                    "format": [
                        "#seq_length_stats.tool.cwl/sequences/FileFormats.cv.yamlfasta", 
                        "#seq_length_stats.tool.cwl/sequences/FileFormats.cv.yamlfastq"
                    ], 
                    "inputBinding": {
                        "prefix": "--input"
                    }, 
                    "id": "#seq_length_stats.tool.cwl/sequences"
                }
            ], 
            "baseCommand": [
                "seq_length_stats.py"
            ], 
            "arguments": [
                {
                    "prefix": "--type", 
                    "valueFrom": "${\n   return inputs.sequences.format.split(\"/\").slice(-1)[0]\n  }\n"
                }
            ], 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#seq_length_stats.tool.cwl/error"
                }, 
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "outputBinding": {
                        "glob": "$(inputs.gc_percent_bin)"
                    }, 
                    "id": "#seq_length_stats.tool.cwl/gc_bin"
                }, 
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "outputBinding": {
                        "glob": "$(inputs.length_bin)"
                    }, 
                    "id": "#seq_length_stats.tool.cwl/len_bin"
                }, 
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "outputBinding": {
                        "glob": "$(inputs.output)"
                    }, 
                    "id": "#seq_length_stats.tool.cwl/stats"
                }, 
                {
                    "type": "stdout", 
                    "id": "#seq_length_stats.tool.cwl/stdout"
                }
            ], 
            "id": "#seq_length_stats.tool.cwl"
        }, 
        {
            "class": "Workflow", 
            "requirements": [
                {
                    "class": "StepInputExpressionRequirement"
                }, 
                {
                    "class": "InlineJavascriptRequirement"
                }, 
                {
                    "class": "ScatterFeatureRequirement"
                }, 
                {
                    "class": "MultipleInputFeatureRequirement"
                }
            ], 
            "inputs": [
                {
                    "type": "int", 
                    "id": "#main/basepairs"
                }, 
                {
                    "type": "string", 
                    "id": "#main/jobid"
                }, 
                {
                    "type": {
                        "type": "array", 
                        "items": "int"
                    }, 
                    "default": [
                        6
                    ], 
                    "id": "#main/kmerLength"
                }, 
                {
                    "type": "File", 
                    "id": "#main/sequences"
                }
            ], 
            "outputs": [
                {
                    "type": "File", 
                    "outputSource": "#main/consensus/consensus", 
                    "id": "#main/consensusFile"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/consensus/consensus", 
                    "id": "#main/consensusStatsFile"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/drisee/info", 
                    "id": "#main/driseeFile"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/drisee/stats", 
                    "id": "#main/driseeStatsFile"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/formatSequenceStats/bins", 
                    "id": "#main/formatSeqStatsBinFile"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/formatSequenceStats/stats", 
                    "id": "#main/formatSeqStatsFile"
                }, 
                {
                    "type": {
                        "type": "array", 
                        "items": {
                            "type": "record", 
                            "label": "none", 
                            "fields": [
                                {
                                    "name": "#main/kmerStruct/length", 
                                    "type": "int"
                                }, 
                                {
                                    "name": "#main/kmerStruct/file", 
                                    "type": "File"
                                }
                            ]
                        }
                    }, 
                    "outputSource": [
                        "#main/kmer/stats"
                    ], 
                    "id": "#main/kmerStruct"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/sequenceStats/stats", 
                    "id": "#main/sequenceStatsFile"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/sequenceStats/gc_bin", 
                    "id": "#main/sequenceStatsGcFile"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/sequenceStats/len_bin", 
                    "id": "#main/sequenceStatsLenFile"
                }
            ], 
            "steps": [
                {
                    "run": "#consensus.tool.cwl", 
                    "in": [
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).100.preprocess.consensus.stats", 
                            "id": "#main/consensus/output"
                        }, 
                        {
                            "source": "#main/sequences", 
                            "id": "#main/consensus/sequences"
                        }, 
                        {
                            "source": "#main/sequenceStats/stats", 
                            "id": "#main/consensus/stats"
                        }
                    ], 
                    "out": [
                        "#main/consensus/summary", 
                        "#main/consensus/error", 
                        "#main/consensus/consensus"
                    ], 
                    "id": "#main/consensus"
                }, 
                {
                    "run": "#drisee.tool.cwl", 
                    "in": [
                        {
                            "source": "#main/sequences", 
                            "id": "#main/drisee/sequences"
                        }
                    ], 
                    "out": [
                        "#main/drisee/info", 
                        "#main/drisee/error", 
                        "#main/drisee/stats"
                    ], 
                    "id": "#main/drisee"
                }, 
                {
                    "run": "#format_qc_stats.tool.cwl", 
                    "in": [
                        {
                            "source": "#main/consensus/consensus", 
                            "id": "#main/formatQcStats/consensus"
                        }, 
                        {
                            "source": "#main/drisee/info", 
                            "id": "#main/formatQcStats/drisee_info"
                        }, 
                        {
                            "source": "#main/drisee/stats", 
                            "id": "#main/formatQcStats/drisee_stat"
                        }, 
                        {
                            "source": "#main/kmer/stats", 
                            "id": "#main/formatQcStats/kmer"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).100.preprocess", 
                            "id": "#main/formatQcStats/output_prefix"
                        }
                    ], 
                    "out": [
                        "#main/formatQcStats/stats", 
                        "#main/formatQcStats/summary"
                    ], 
                    "id": "#main/formatQcStats"
                }, 
                {
                    "run": "#format_seq_stats.tool.cwl", 
                    "in": [
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).100.preprocess", 
                            "id": "#main/formatSequenceStats/output_prefix"
                        }, 
                        {
                            "source": "#main/sequenceStats/gc_bin", 
                            "id": "#main/formatSequenceStats/sequence_gc"
                        }, 
                        {
                            "source": "#main/sequenceStats/len_bin", 
                            "id": "#main/formatSequenceStats/sequence_lengths"
                        }, 
                        {
                            "source": "#main/sequenceStats/stats", 
                            "id": "#main/formatSequenceStats/sequence_stats"
                        }
                    ], 
                    "out": [
                        "#main/formatSequenceStats/stats", 
                        "#main/formatSequenceStats/bins"
                    ], 
                    "id": "#main/formatSequenceStats"
                }, 
                {
                    "run": "#kmer-tool.tool.cwl", 
                    "scatter": "#main/kmer/length", 
                    "in": [
                        {
                            "source": "#main/kmerLength", 
                            "id": "#main/kmer/length"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).100.preprocess", 
                            "id": "#main/kmer/prefix"
                        }, 
                        {
                            "source": "#main/sequences", 
                            "id": "#main/kmer/sequences"
                        }
                    ], 
                    "out": [
                        "#main/kmer/summary", 
                        "#main/kmer/error", 
                        "#main/kmer/stats"
                    ], 
                    "id": "#main/kmer"
                }, 
                {
                    "run": "#seq_length_stats.tool.cwl", 
                    "in": [
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).100.preprocess.gc.bin", 
                            "id": "#main/sequenceStats/gc_percent_bin"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).100.preprocess.length.bin", 
                            "id": "#main/sequenceStats/length_bin"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).100.preprocess.length.stats", 
                            "id": "#main/sequenceStats/output"
                        }, 
                        {
                            "source": "#main/sequences", 
                            "id": "#main/sequenceStats/sequences"
                        }
                    ], 
                    "out": [
                        "#main/sequenceStats/stats", 
                        "#main/sequenceStats/len_bin", 
                        "#main/sequenceStats/gc_bin"
                    ], 
                    "id": "#main/sequenceStats"
                }
            ], 
            "id": "#main"
        }
    ]
}