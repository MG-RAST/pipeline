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
                    "default": 6, 
                    "type": [
                        "null", 
                        "int"
                    ], 
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
                }
            ], 
            "outputs": [
                {
                    "outputSource": "#main/consensus/consensus", 
                    "type": "File", 
                    "id": "#main/consensusFile"
                }, 
                {
                    "outputSource": "#main/kmer/stats", 
                    "type": "File", 
                    "id": "#main/kmerFile"
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
                    "requirements": [
                        {
                            "class": "InitialWorkDirRequirement", 
                            "listing": [
                                {
                                    "entry": "{\n  \"stage_id\": \"150\",\n  \"stage_name\": \"dereplication workflow\",\n  \"file_format\": \"fasta\",\n  \"seq_format\": \"bp\"\n} \n", 
                                    "entryname": "userattr.json"
                                }
                            ]
                        }
                    ], 
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
                            "valueFrom": "$(self).100.preprocess", 
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