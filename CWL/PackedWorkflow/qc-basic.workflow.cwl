{
    "cwlVersion": "v1.0", 
    "$graph": [
        {
            "inputs": [
                {
                    "doc": "max number of bps to process [default 100]", 
                    "inputBinding": {
                        "prefix": "--bp_max"
                    }, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#consensus.tool.cwl/basepairs"
                }, 
                {
                    "doc": "Output file.", 
                    "inputBinding": {
                        "prefix": "--output"
                    }, 
                    "type": "string", 
                    "id": "#consensus.tool.cwl/output"
                }, 
                {
                    "doc": "Input file, sequence (fasta/fastq).", 
                    "inputBinding": {
                        "prefix": "--input"
                    }, 
                    "type": "File", 
                    "id": "#consensus.tool.cwl/sequences", 
                    "format": [
                        "#consensus.tool.cwl/sequences/FileFormats.cv.yamlfasta", 
                        "#consensus.tool.cwl/sequences/FileFormats.cv.yamlfastq"
                    ]
                }, 
                {
                    "inputBinding": {
                        "prefix": "--stats"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#consensus.tool.cwl/stats"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "consensus.log", 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.output)"
                    }, 
                    "type": "File", 
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
            "baseCommand": [
                "consensus.py"
            ], 
            "class": "CommandLineTool", 
            "arguments": [
                {
                    "prefix": "--verbose"
                }, 
                {
                    "prefix": "--type", 
                    "valueFrom": "${\n   return inputs.sequences.format.split(\"/\").slice(-1)[0]\n  } \n"
                }
            ], 
            "stderr": "consensus.error", 
            "$namespaces": {
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#consensus.tool.cwl", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:4.03", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "inputBinding": {
                        "position": 1
                    }, 
                    "type": "File", 
                    "id": "#drisee.tool.cwl/sequences", 
                    "format": [
                        "#drisee.tool.cwl/sequences/FileFormats.cv.yamlfasta", 
                        "#drisee.tool.cwl/sequences/FileFormats.cv.yamlfastq"
                    ]
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "drisee.log", 
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
                    "outputBinding": {
                        "glob": "drisee.stats"
                    }, 
                    "type": "File", 
                    "id": "#drisee.tool.cwl/stats"
                }
            ], 
            "baseCommand": [
                "drisee"
            ], 
            "class": "CommandLineTool", 
            "arguments": [
                {
                    "position": 2, 
                    "valueFrom": "drisee.stats"
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
            "stderr": "drisee.error", 
            "$namespaces": {
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#drisee.tool.cwl", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:4.03", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "doc": "consensus stat file", 
                    "inputBinding": {
                        "prefix": "-consensus"
                    }, 
                    "type": "File", 
                    "id": "#format_qc_stats.tool.cwl/consensus"
                }, 
                {
                    "doc": "coverage stat file", 
                    "inputBinding": {
                        "prefix": "-coverage"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#format_qc_stats.tool.cwl/coverage"
                }, 
                {
                    "doc": "drisee info file", 
                    "inputBinding": {
                        "prefix": "-drisee_info"
                    }, 
                    "type": "File", 
                    "id": "#format_qc_stats.tool.cwl/drisee_info"
                }, 
                {
                    "doc": "drisee stat file", 
                    "inputBinding": {
                        "prefix": "-drisee_stat"
                    }, 
                    "type": "File", 
                    "id": "#format_qc_stats.tool.cwl/drisee_stat"
                }, 
                {
                    "type": {
                        "items": {
                            "fields": [
                                {
                                    "type": "int", 
                                    "name": "#format_qc_stats.tool.cwl/kmer/length"
                                }, 
                                {
                                    "type": "File", 
                                    "name": "#format_qc_stats.tool.cwl/kmer/file"
                                }
                            ], 
                            "type": "record"
                        }, 
                        "type": "array"
                    }, 
                    "id": "#format_qc_stats.tool.cwl/kmer"
                }, 
                {
                    "doc": "output prefix = ${output_prefix}.seq.bins, ${output_prefix}.seq.stats", 
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "type": "string", 
                    "id": "#format_qc_stats.tool.cwl/output_prefix"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "format_qc_stats.stats", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#format_qc_stats.tool.cwl/error"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.output_prefix).qc.stats"
                    }, 
                    "type": "File", 
                    "id": "#format_qc_stats.tool.cwl/stats"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.output_prefix).qc.summary"
                    }, 
                    "type": "File", 
                    "id": "#format_qc_stats.tool.cwl/summary"
                }
            ], 
            "baseCommand": [
                "format_qc_stats.pl"
            ], 
            "class": "CommandLineTool", 
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
            "stderr": "format_qc_stats.error", 
            "id": "#format_qc_stats.tool.cwl", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:4.03", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "doc": "output prefix, e.g. ${output_prefix}.seq.bins, ${output_prefix}.seq.stats", 
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "type": "string", 
                    "id": "#format_seq_stats.tool.cwl/output_prefix"
                }, 
                {
                    "doc": "gc bin file", 
                    "inputBinding": {
                        "prefix": "-seq_gc"
                    }, 
                    "type": "File", 
                    "id": "#format_seq_stats.tool.cwl/sequence_gc"
                }, 
                {
                    "doc": "len bin file", 
                    "inputBinding": {
                        "prefix": "-seq_lens"
                    }, 
                    "type": "File", 
                    "id": "#format_seq_stats.tool.cwl/sequence_lengths"
                }, 
                {
                    "doc": "stats tabbed file", 
                    "inputBinding": {
                        "prefix": "-seq_stat"
                    }, 
                    "type": "File", 
                    "id": "#format_seq_stats.tool.cwl/sequence_stats"
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.output_prefix).seq.bins"
                    }, 
                    "type": "File", 
                    "id": "#format_seq_stats.tool.cwl/bins"
                }, 
                {
                    "type": "stderr", 
                    "id": "#format_seq_stats.tool.cwl/error"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.output_prefix).seq.stats"
                    }, 
                    "type": "File", 
                    "id": "#format_seq_stats.tool.cwl/stats", 
                    "format": "file:///Users/Andi/Development/MG-RAST-Repo/pipeline/CWL/Tools/json"
                }
            ], 
            "stdout": "format_seq_stats.stats", 
            "baseCommand": [
                "format_seq_stats.pl"
            ], 
            "class": "CommandLineTool", 
            "stderr": "format_seq_stats.error", 
            "id": "#format_seq_stats.tool.cwl", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:4.03", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "default": 6, 
                    "doc": "Length of kmer to use, eg. 6 or 15", 
                    "inputBinding": {
                        "prefix": "--length"
                    }, 
                    "type": "int", 
                    "id": "#kmer-tool.tool.cwl/length"
                }, 
                {
                    "default": "qc", 
                    "doc": "Prefix for output file(s)", 
                    "type": "string", 
                    "id": "#kmer-tool.tool.cwl/prefix"
                }, 
                {
                    "doc": "Input file, sequence (fasta/fastq) or binary count hash (hash).", 
                    "inputBinding": {
                        "prefix": "--input"
                    }, 
                    "type": "File", 
                    "id": "#kmer-tool.tool.cwl/sequences", 
                    "format": [
                        "Formats:fasta", 
                        "Formats:fastq", 
                        "Formats:hash"
                    ]
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "kmer-tool.log", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#kmer-tool.tool.cwl/error"
                }, 
                {
                    "type": {
                        "fields": [
                            {
                                "outputBinding": {
                                    "outputEval": "$(inputs.length)"
                                }, 
                                "type": "int", 
                                "name": "#kmer-tool.tool.cwl/stats/length"
                            }, 
                            {
                                "outputBinding": {
                                    "glob": "$(inputs.prefix).kmer.$(inputs.length).stats"
                                }, 
                                "type": "File", 
                                "name": "#kmer-tool.tool.cwl/stats/file"
                            }
                        ], 
                        "type": "record", 
                        "label": "none"
                    }, 
                    "id": "#kmer-tool.tool.cwl/stats"
                }, 
                {
                    "type": "stdout", 
                    "id": "#kmer-tool.tool.cwl/summary"
                }
            ], 
            "baseCommand": [
                "kmer-tool"
            ], 
            "class": "CommandLineTool", 
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
            "stderr": "kmer-tool.error", 
            "$namespaces": {
                "format": "file:///Users/Andi/Development/MG-RAST-Repo/pipeline/CWL/Tools/FileFormats.cv.yaml"
            }, 
            "id": "#kmer-tool.tool.cwl", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:4.03", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "default": false, 
                    "inputBinding": {
                        "prefix": "--fast"
                    }, 
                    "type": "boolean", 
                    "id": "#seq_length_stats.tool.cwl/fast"
                }, 
                {
                    "doc": "Filename to place gc bins", 
                    "inputBinding": {
                        "prefix": "--gc_percent_bin"
                    }, 
                    "type": "string", 
                    "id": "#seq_length_stats.tool.cwl/gc_percent_bin"
                }, 
                {
                    "default": false, 
                    "inputBinding": {
                        "prefix": "--seq_type"
                    }, 
                    "type": "boolean", 
                    "id": "#seq_length_stats.tool.cwl/guess_seq_type"
                }, 
                {
                    "default": false, 
                    "doc": "Ignore commas in header ID", 
                    "inputBinding": {
                        "prefix": "--ignore_comma"
                    }, 
                    "type": "boolean", 
                    "id": "#seq_length_stats.tool.cwl/ignore_comma"
                }, 
                {
                    "doc": "Filename to place length bins [default is no output]", 
                    "inputBinding": {
                        "prefix": "--length_bin"
                    }, 
                    "type": "string", 
                    "id": "#seq_length_stats.tool.cwl/length_bin"
                }, 
                {
                    "doc": "Output stats file, if not called prints to STDOUT", 
                    "inputBinding": {
                        "prefix": "--output"
                    }, 
                    "type": "string", 
                    "id": "#seq_length_stats.tool.cwl/output"
                }, 
                {
                    "default": 100000, 
                    "doc": "max number of seqs to process (for kmer entropy)", 
                    "inputBinding": {
                        "prefix": "--seq_max"
                    }, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#seq_length_stats.tool.cwl/seq_max"
                }, 
                {
                    "doc": "Input file, sequence (fasta/fastq)", 
                    "inputBinding": {
                        "prefix": "--input"
                    }, 
                    "type": "File", 
                    "id": "#seq_length_stats.tool.cwl/sequences", 
                    "format": [
                        "#seq_length_stats.tool.cwl/sequences/FileFormats.cv.yamlfasta", 
                        "#seq_length_stats.tool.cwl/sequences/FileFormats.cv.yamlfastq"
                    ]
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "seq_length_stats.stats", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#seq_length_stats.tool.cwl/error"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.gc_percent_bin)"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#seq_length_stats.tool.cwl/gc_bin"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.length_bin)"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#seq_length_stats.tool.cwl/len_bin"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.output)"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#seq_length_stats.tool.cwl/stats"
                }, 
                {
                    "type": "stdout", 
                    "id": "#seq_length_stats.tool.cwl/stdout"
                }
            ], 
            "baseCommand": [
                "seq_length_stats.py"
            ], 
            "class": "CommandLineTool", 
            "arguments": [
                {
                    "prefix": "--type", 
                    "valueFrom": "${\n   return inputs.sequences.format.split(\"/\").slice(-1)[0]\n  }\n"
                }
            ], 
            "stderr": "seq_length_stats.error", 
            "$namespaces": {
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#seq_length_stats.tool.cwl", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:4.03", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
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
                    "default": [
                        6
                    ], 
                    "type": {
                        "items": "int", 
                        "type": "array"
                    }, 
                    "id": "#main/kmerLength"
                }, 
                {
                    "type": "File", 
                    "id": "#main/sequences"
                }
            ], 
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
            "outputs": [
                {
                    "outputSource": "#main/consensus/consensus", 
                    "type": "File", 
                    "id": "#main/consensusFile"
                }, 
                {
                    "outputSource": "#main/consensus/consensus", 
                    "type": "File", 
                    "id": "#main/consensusStatsFile"
                }, 
                {
                    "outputSource": "#main/drisee/info", 
                    "type": "File", 
                    "id": "#main/driseeFile"
                }, 
                {
                    "outputSource": "#main/drisee/stats", 
                    "type": "File", 
                    "id": "#main/driseeStatsFile"
                }, 
                {
                    "outputSource": "#main/formatSequenceStats/bins", 
                    "type": "File", 
                    "id": "#main/formatSeqStatsBinFile"
                }, 
                {
                    "outputSource": "#main/formatSequenceStats/stats", 
                    "type": "File", 
                    "id": "#main/formatSeqStatsFile"
                }, 
                {
                    "outputSource": [
                        "#main/kmer/stats"
                    ], 
                    "type": {
                        "items": {
                            "fields": [
                                {
                                    "type": "int", 
                                    "name": "#main/kmerStruct/length"
                                }, 
                                {
                                    "type": "File", 
                                    "name": "#main/kmerStruct/file"
                                }
                            ], 
                            "type": "record", 
                            "label": "none"
                        }, 
                        "type": "array"
                    }, 
                    "id": "#main/kmerStruct"
                }, 
                {
                    "outputSource": "#main/sequenceStats/stats", 
                    "type": "File", 
                    "id": "#main/sequenceStatsFile"
                }, 
                {
                    "outputSource": "#main/sequenceStats/gc_bin", 
                    "type": "File", 
                    "id": "#main/sequenceStatsGcFile"
                }, 
                {
                    "outputSource": "#main/sequenceStats/len_bin", 
                    "type": "File", 
                    "id": "#main/sequenceStatsLenFile"
                }
            ], 
            "id": "#main", 
            "steps": [
                {
                    "out": [
                        "#main/consensus/summary", 
                        "#main/consensus/error", 
                        "#main/consensus/consensus"
                    ], 
                    "run": "#consensus.tool.cwl", 
                    "id": "#main/consensus", 
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
                    ]
                }, 
                {
                    "out": [
                        "#main/drisee/info", 
                        "#main/drisee/error", 
                        "#main/drisee/stats"
                    ], 
                    "run": "#drisee.tool.cwl", 
                    "id": "#main/drisee", 
                    "in": [
                        {
                            "source": "#main/sequences", 
                            "id": "#main/drisee/sequences"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/formatQcStats/stats", 
                        "#main/formatQcStats/summary"
                    ], 
                    "run": "#format_qc_stats.tool.cwl", 
                    "id": "#main/formatQcStats", 
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
                    ]
                }, 
                {
                    "out": [
                        "#main/formatSequenceStats/stats", 
                        "#main/formatSequenceStats/bins"
                    ], 
                    "run": "#format_seq_stats.tool.cwl", 
                    "id": "#main/formatSequenceStats", 
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
                    ]
                }, 
                {
                    "scatter": "#main/kmer/length", 
                    "out": [
                        "#main/kmer/summary", 
                        "#main/kmer/error", 
                        "#main/kmer/stats"
                    ], 
                    "run": "#kmer-tool.tool.cwl", 
                    "id": "#main/kmer", 
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
                    ]
                }, 
                {
                    "out": [
                        "#main/sequenceStats/stats", 
                        "#main/sequenceStats/len_bin", 
                        "#main/sequenceStats/gc_bin"
                    ], 
                    "run": "#seq_length_stats.tool.cwl", 
                    "id": "#main/sequenceStats", 
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
                    ]
                }
            ], 
            "class": "Workflow"
        }
    ]
}