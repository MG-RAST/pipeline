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
                }, 
                {
                    "types": [
                        {
                            "type": "enum", 
                            "name": "#FileFormats.cv.yaml/FileFormat", 
                            "symbols": [
                                "#FileFormats.cv.yaml/FileFormat/fasta", 
                                "#FileFormats.cv.yaml/FileFormat/fastq", 
                                "#FileFormats.cv.yaml/FileFormat/hash"
                            ], 
                            "id": "#FileFormats.cv.yaml"
                        }
                    ], 
                    "class": "SchemaDefRequirement"
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
                    "type": "File", 
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
            "s:license": "https://www.apache.org/licenses/LICENSE-2.0", 
            "s:copyrightHolder": "MG-RAST", 
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
                }, 
                {
                    "types": [
                        {
                            "$import": "#FileFormats.cv.yaml"
                        }
                    ], 
                    "class": "SchemaDefRequirement"
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
                        "#kmer-tool.tool.cwl/sequences/FileFormats.cv.yamlfasta", 
                        "#kmer-tool.tool.cwl/sequences/FileFormats.cv.yamlfastq", 
                        "#kmer-tool.tool.cwl/sequences/FileFormats.cv.yamlhash"
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
                {
                    "prefix": "--ranked"
                }, 
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
                    "type": "File", 
                    "outputBinding": {
                        "glob": "$(inputs.prefix).kmer.$(inputs.length).stats"
                    }, 
                    "id": "#kmer-tool.tool.cwl/stats"
                }, 
                {
                    "type": "stdout", 
                    "id": "#kmer-tool.tool.cwl/summary"
                }
            ], 
            "s:license": "https://www.apache.org/licenses/LICENSE-2.0", 
            "s:copyrightHolder": "MG-RAST", 
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
                }, 
                {
                    "types": [
                        {
                            "$import": "#FileFormats.cv.yaml"
                        }
                    ], 
                    "class": "SchemaDefRequirement"
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
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "doc": null, 
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
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "doc": "File to place length bins [default is no output]", 
                    "inputBinding": {
                        "prefix": "--length_bin"
                    }, 
                    "id": "#seq_length_stats.tool.cwl/length_bin"
                }, 
                {
                    "type": [
                        "null", 
                        "string"
                    ], 
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
                    "type": "stdout", 
                    "id": "#seq_length_stats.tool.cwl/stats"
                }
            ], 
            "id": "#seq_length_stats.tool.cwl"
        }, 
        {
            "class": "Workflow", 
            "requirements": [
                {
                    "class": "StepInputExpressionRequirement"
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
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "default": 6, 
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
                    "outputSource": "#main/kmer/stats", 
                    "id": "#main/kmerFile"
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
                    "requirements": [
                        {
                            "class": "InitialWorkDirRequirement", 
                            "listing": [
                                {
                                    "entryname": "userattr.json", 
                                    "entry": "{\n  \"stage_id\": \"150\",\n  \"stage_name\": \"dereplication workflow\",\n  \"file_format\": \"fasta\",\n  \"seq_format\": \"bp\"\n} \n"
                                }
                            ]
                        }
                    ], 
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
                    ], 
                    "out": [
                        "#main/consensus/summary", 
                        "#main/consensus/error", 
                        "#main/consensus/consensus"
                    ], 
                    "id": "#main/consensus"
                }, 
                {
                    "run": "#kmer-tool.tool.cwl", 
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