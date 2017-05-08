{
    "cwlVersion": "v1.0", 
    "$graph": [
        {
            "inputs": [
                {
                    "default": 1, 
                    "inputBinding": {
                        "prefix": "-dereplicate"
                    }, 
                    "type": "int", 
                    "id": "#awe_dereplicate.tool.yaml/dereplicate"
                }, 
                {
                    "inputBinding": {
                        "valueFrom": "$(self.basename)", 
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#awe_dereplicate.tool.yaml/input"
                }, 
                {
                    "default": "$(runtime.ram)", 
                    "inputBinding": {
                        "prefix": "-memory"
                    }, 
                    "type": "int", 
                    "id": "#awe_dereplicate.tool.yaml/memory"
                }, 
                {
                    "default": false, 
                    "inputBinding": {
                        "prefix": "-no-shock"
                    }, 
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "id": "#awe_dereplicate.tool.yaml/no-shock"
                }, 
                {
                    "default": "derep", 
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "type": "string", 
                    "id": "#awe_dereplicate.tool.yaml/out_prefix"
                }, 
                {
                    "default": 50, 
                    "inputBinding": {
                        "prefix": "-prefix_length"
                    }, 
                    "type": "int", 
                    "id": "#awe_dereplicate.tool.yaml/prefix_length"
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        "$(inputs.input)", 
                        {
                            "entry": "{\n  \"stage_id\": \"150\",\n  \"stage_name\": \"dereplication\",\n  \"file_format\": \"fasta\",\n  \"seq_format\": \"bp\"\n}\n", 
                            "entryname": "userattr.json"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "*.json"
                    }, 
                    "type": [
                        "null", 
                        {
                            "items": "File", 
                            "type": "array"
                        }
                    ], 
                    "id": "#awe_dereplicate.tool.yaml/attributes"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).passed.fna"
                    }, 
                    "type": "File", 
                    "id": "#awe_dereplicate.tool.yaml/passed"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).removed.fna"
                    }, 
                    "type": "File", 
                    "id": "#awe_dereplicate.tool.yaml/removed"
                }
            ], 
            "baseCommand": "awe_dereplicate.pl", 
            "class": "CommandLineTool", 
            "id": "#awe_dereplicate.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/dereplicate:1.0", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "default": "dynamic_trim:min_qual=15:max_lqb=5", 
                    "inputBinding": {
                        "prefix": "-filter_options"
                    }, 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#awe_preprocess.tool.yaml/filter_options"
                }, 
                {
                    "doc": "fasta or fastq", 
                    "inputBinding": {
                        "prefix": "-format"
                    }, 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#awe_preprocess.tool.yaml/format"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#awe_preprocess.tool.yaml/input"
                }, 
                {
                    "default": false, 
                    "inputBinding": {
                        "prefix": "-no-shock"
                    }, 
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "id": "#awe_preprocess.tool.yaml/no-shock"
                }, 
                {
                    "default": "prep", 
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "type": "string", 
                    "id": "#awe_preprocess.tool.yaml/out_prefix"
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        {
                            "entry": "{\n  \"stage_id\": \"100\",\n  \"stage_name\": \"preprocess\",\n  \"file_format\": \"fasta\",\n  \"seq_format\": \"bp\"\n}\n", 
                            "entryname": "userattr.json"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "*.json"
                    }, 
                    "type": [
                        "null", 
                        {
                            "items": "File", 
                            "type": "array"
                        }
                    ], 
                    "id": "#awe_preprocess.tool.yaml/attributes"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).passed.fna"
                    }, 
                    "type": "File", 
                    "id": "#awe_preprocess.tool.yaml/passed"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).removed.fna"
                    }, 
                    "type": "File", 
                    "id": "#awe_preprocess.tool.yaml/removed"
                }
            ], 
            "baseCommand": "awe_preprocess.pl", 
            "class": "CommandLineTool", 
            "id": "#awe_preprocess.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/preprocess:1.0", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "default": 0, 
                    "doc": "<0 or 1, default 0>", 
                    "inputBinding": {
                        "prefix": "-assembled"
                    }, 
                    "type": "int", 
                    "id": "#awe_qc.tool.yaml/assembled"
                }, 
                {
                    "doc": "Default: <filter_ln:min_ln=<MIN>:max_ln=<MAX>:filter_ambig:max_ambig=5:dynamic_trim:min_qual=15:max_lqb=5>", 
                    "inputBinding": {
                        "prefix": "-filter_options"
                    }, 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#awe_qc.tool.yaml/filter_options"
                }, 
                {
                    "doc": "<fasta|fastq>", 
                    "inputBinding": {
                        "prefix": "-format"
                    }, 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#awe_qc.tool.yaml/format"
                }, 
                {
                    "default": "15,6", 
                    "inputBinding": {
                        "prefix": "-kmers"
                    }, 
                    "type": "string", 
                    "id": "#awe_qc.tool.yaml/kmers"
                }, 
                {
                    "default": "qc", 
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "type": "string", 
                    "id": "#awe_qc.tool.yaml/out_prefix"
                }, 
                {
                    "default": 8, 
                    "inputBinding": {
                        "prefix": "-proc"
                    }, 
                    "type": "int", 
                    "id": "#awe_qc.tool.yaml/proc"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#awe_qc.tool.yaml/seqfile"
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        {
                            "entry": "{\n  \"stage_id\": \"075\",\n  \"stage_name\": \"qc\"\n}\n", 
                            "entryname": "userattr.json"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).assembly.coverage"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#awe_qc.tool.yaml/assembly"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).assembly.coverage.json"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#awe_qc.tool.yaml/assemblyattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).consensus.stats"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#awe_qc.tool.yaml/consensus"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).consensus.stats.json"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#awe_qc.tool.yaml/consensusattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).drisee.stats"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#awe_qc.tool.yaml/drisee"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).drisee.stats.json"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#awe_qc.tool.yaml/driseeattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).drisee.info"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#awe_qc.tool.yaml/driseeinfo"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).drisee.info.json"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#awe_qc.tool.yaml/driseeinfoattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).kmer.*.stats"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#awe_qc.tool.yaml/kmer"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).kmer.*.stats.json"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#awe_qc.tool.yaml/kmerattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).qc.stats"
                    }, 
                    "type": "File", 
                    "id": "#awe_qc.tool.yaml/qcstats"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).qc.stats.json"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#awe_qc.tool.yaml/qcstatsattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).upload.stats"
                    }, 
                    "type": "File", 
                    "id": "#awe_qc.tool.yaml/uploadstats"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).upload.stats.json"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#awe_qc.tool.yaml/uploadstatsattr"
                }
            ], 
            "baseCommand": "awe_qc.pl", 
            "class": "CommandLineTool", 
            "id": "#awe_qc.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/qc:1.0", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#main/api_key"
                }, 
                {
                    "type": "int", 
                    "id": "#main/assembled"
                }, 
                {
                    "default": 10, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#main/derep_memory"
                }, 
                {
                    "type": "int", 
                    "id": "#main/derep_prefix_length"
                }, 
                {
                    "type": "int", 
                    "id": "#main/dereplicate"
                }, 
                {
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#main/filter_options"
                }, 
                {
                    "type": "int", 
                    "id": "#main/jobid"
                }, 
                {
                    "default": true, 
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "id": "#main/no-shock"
                }, 
                {
                    "default": "6,15", 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#main/qc_kmers"
                }, 
                {
                    "default": 8, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#main/qc_proc"
                }, 
                {
                    "type": "string", 
                    "id": "#main/seqformat"
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
                    "outputSource": "#main/dereplication/attributes", 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#main/derepAttr"
                }, 
                {
                    "outputSource": "#main/dereplication/passed", 
                    "type": "File", 
                    "id": "#main/derepPassed"
                }, 
                {
                    "outputSource": "#main/dereplication/removed", 
                    "type": "File", 
                    "id": "#main/derepRemoved"
                }, 
                {
                    "outputSource": "#main/preprocess/passed", 
                    "type": "File", 
                    "id": "#main/out"
                }, 
                {
                    "outputSource": "#main/preprocess/removed", 
                    "type": "File", 
                    "id": "#main/removed"
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
                        "#main/dereplication/passed", 
                        "#main/dereplication/removed", 
                        "#main/dereplication/attributes"
                    ], 
                    "run": "#awe_dereplicate.tool.yaml", 
                    "id": "#main/dereplication", 
                    "in": [
                        {
                            "source": "#main/dereplicate", 
                            "id": "#main/dereplication/dereplicate"
                        }, 
                        {
                            "source": "#main/preprocess/passed", 
                            "id": "#main/dereplication/input"
                        }, 
                        {
                            "source": "#main/derep_memory", 
                            "id": "#main/dereplication/memory"
                        }, 
                        {
                            "source": "#main/no-shock", 
                            "id": "#main/dereplication/no-shock"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).150.dereplication", 
                            "id": "#main/dereplication/out_prefix"
                        }, 
                        {
                            "source": "#main/derep_prefix_length", 
                            "id": "#main/dereplication/prefix_length"
                        }
                    ]
                }, 
                {
                    "requirements": [
                        {
                            "envDef": [
                                {
                                    "envName": "MGRAST_WEBKEY", 
                                    "envValue": "api_key"
                                }
                            ], 
                            "class": "EnvVarRequirement"
                        }
                    ], 
                    "out": [
                        "#main/preprocess/removed", 
                        "#main/preprocess/passed"
                    ], 
                    "run": "#awe_preprocess.tool.yaml", 
                    "id": "#main/preprocess", 
                    "in": [
                        {
                            "source": "#main/filter_options", 
                            "id": "#main/preprocess/filter_options"
                        }, 
                        {
                            "source": "#main/seqformat", 
                            "id": "#main/preprocess/format"
                        }, 
                        {
                            "source": "#main/sequences", 
                            "id": "#main/preprocess/input"
                        }, 
                        {
                            "source": "#main/no-shock", 
                            "id": "#main/preprocess/no-shock"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).100.preprocess", 
                            "id": "#main/preprocess/out_prefix"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/qc/assembly", 
                        "#main/qc/qcstats", 
                        "#main/qc/uploadstats"
                    ], 
                    "run": "#awe_qc.tool.yaml", 
                    "id": "#main/qc", 
                    "in": [
                        {
                            "source": "#main/filter_options", 
                            "id": "#main/qc/filter_options"
                        }, 
                        {
                            "source": "#main/seqformat", 
                            "id": "#main/qc/format"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).075", 
                            "id": "#main/qc/out_prefix"
                        }, 
                        {
                            "source": "#main/qc_proc", 
                            "id": "#main/qc/proc"
                        }, 
                        {
                            "source": "#main/sequences", 
                            "id": "#main/qc/seqfile"
                        }
                    ]
                }
            ], 
            "class": "Workflow"
        }
    ]
}