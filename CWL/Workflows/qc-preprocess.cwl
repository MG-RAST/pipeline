{
    "cwlVersion": "v1.0", 
    "$graph": [
        {
            "class": "CommandLineTool", 
            "baseCommand": "awe_preprocess.pl", 
            "hints": [
                {
                    "dockerPull": "mgrast/preprocess:1.0", 
                    "class": "DockerRequirement"
                }
            ], 
            "requirements": [
                {
                    "listing": [
                        {
                            "entryname": "userattr.json", 
                            "entry": "{\n  \"stage_id\": \"100\",\n  \"stage_name\": \"preprocess\",\n  \"file_format\": \"fasta\",\n  \"seq_format\": \"bp\"\n}\n"
                        }
                    ], 
                    "class": "InitialWorkDirRequirement"
                }
            ], 
            "inputs": [
                {
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "default": "dynamic_trim:min_qual=15:max_lqb=5", 
                    "inputBinding": {
                        "prefix": "-filter_options"
                    }, 
                    "id": "#awe_preprocess.tool.yaml/filter_options"
                }, 
                {
                    "doc": "fasta or fastq", 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "inputBinding": {
                        "prefix": "-format"
                    }, 
                    "id": "#awe_preprocess.tool.yaml/format"
                }, 
                {
                    "type": "File", 
                    "inputBinding": {
                        "prefix": "-input"
                    }, 
                    "id": "#awe_preprocess.tool.yaml/input"
                }, 
                {
                    "type": "string", 
                    "default": "prep", 
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "id": "#awe_preprocess.tool.yaml/out_prefix"
                }
            ], 
            "outputs": [
                {
                    "type": [
                        "null", 
                        {
                            "type": "array", 
                            "items": "File"
                        }
                    ], 
                    "outputBinding": {
                        "glob": "*.json"
                    }, 
                    "id": "#awe_preprocess.tool.yaml/attributes"
                }, 
                {
                    "type": "File", 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).passed.fna"
                    }, 
                    "id": "#awe_preprocess.tool.yaml/passed"
                }, 
                {
                    "type": "File", 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).removed.fna"
                    }, 
                    "id": "#awe_preprocess.tool.yaml/removed"
                }
            ], 
            "id": "#awe_preprocess.tool.yaml"
        }, 
        {
            "class": "CommandLineTool", 
            "baseCommand": "awe_qc.pl", 
            "hints": [
                {
                    "dockerPull": "mgrast/qc:1.0", 
                    "class": "DockerRequirement"
                }
            ], 
            "requirements": [
                {
                    "listing": [
                        {
                            "entryname": "userattr.json", 
                            "entry": "{\n  \"stage_id\": \"075\",\n  \"stage_name\": \"qc\"\n}\n"
                        }
                    ], 
                    "class": "InitialWorkDirRequirement"
                }
            ], 
            "inputs": [
                {
                    "type": "int", 
                    "default": "0", 
                    "inputBinding": {
                        "prefix": "-assembled"
                    }, 
                    "id": "#awe_qc.tool.yaml/assembled"
                }, 
                {
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "doc": "Default: <filter_ln:min_ln=<MIN>:max_ln=<MAX>:filter_ambig:max_ambig=5:dynamic_trim:min_qual=15:max_lqb=5>", 
                    "inputBinding": {
                        "prefix": "-filter_options"
                    }, 
                    "id": "#awe_qc.tool.yaml/filter_options"
                }, 
                {
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "doc": "<fasta|fastq>", 
                    "inputBinding": {
                        "prefix": "-format"
                    }, 
                    "id": "#awe_qc.tool.yaml/format"
                }, 
                {
                    "type": "string", 
                    "default": "15,6", 
                    "inputBinding": {
                        "prefix": "-kmers"
                    }, 
                    "id": "#awe_qc.tool.yaml/kmers"
                }, 
                {
                    "type": "string", 
                    "default": "qc", 
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "id": "#awe_qc.tool.yaml/out_prefix"
                }, 
                {
                    "type": "int", 
                    "default": 8, 
                    "inputBinding": {
                        "prefix": "-proc"
                    }, 
                    "id": "#awe_qc.tool.yaml/proc"
                }, 
                {
                    "type": "File", 
                    "inputBinding": {
                        "prefix": "-input"
                    }, 
                    "id": "#awe_qc.tool.yaml/seqfile"
                }
            ], 
            "outputs": [
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).assembly.coverage"
                    }, 
                    "id": "#awe_qc.tool.yaml/assembly"
                }, 
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).assembly.coverage.json"
                    }, 
                    "id": "#awe_qc.tool.yaml/assemblyattr"
                }, 
                {
                    "type": {
                        "type": "array", 
                        "items": "File"
                    }, 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).consensus.stats"
                    }, 
                    "id": "#awe_qc.tool.yaml/consensus"
                }, 
                {
                    "type": {
                        "type": "array", 
                        "items": "File"
                    }, 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).consensus.stats.json"
                    }, 
                    "id": "#awe_qc.tool.yaml/consensusattr"
                }, 
                {
                    "type": {
                        "type": "array", 
                        "items": "File"
                    }, 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).drisee.stats"
                    }, 
                    "id": "#awe_qc.tool.yaml/drisee"
                }, 
                {
                    "type": {
                        "type": "array", 
                        "items": "File"
                    }, 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).drisee.stats.json"
                    }, 
                    "id": "#awe_qc.tool.yaml/driseeattr"
                }, 
                {
                    "type": {
                        "type": "array", 
                        "items": "File"
                    }, 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).drisee.info"
                    }, 
                    "id": "#awe_qc.tool.yaml/driseeinfo"
                }, 
                {
                    "type": {
                        "type": "array", 
                        "items": "File"
                    }, 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).drisee.info.json"
                    }, 
                    "id": "#awe_qc.tool.yaml/driseeinfoattr"
                }, 
                {
                    "type": {
                        "type": "array", 
                        "items": "File"
                    }, 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).kmer.*.stats"
                    }, 
                    "id": "#awe_qc.tool.yaml/kmer"
                }, 
                {
                    "type": {
                        "type": "array", 
                        "items": "File"
                    }, 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).kmer.*.stats.json"
                    }, 
                    "id": "#awe_qc.tool.yaml/kmerattr"
                }, 
                {
                    "type": "File", 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).qc.stats"
                    }, 
                    "id": "#awe_qc.tool.yaml/qcstats"
                }, 
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).qc.stats.json"
                    }, 
                    "id": "#awe_qc.tool.yaml/qcstatsattr"
                }, 
                {
                    "type": "File", 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).upload.stats"
                    }, 
                    "id": "#awe_qc.tool.yaml/uploadstats"
                }, 
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).upload.stats.json"
                    }, 
                    "id": "#awe_qc.tool.yaml/uploadstatsattr"
                }
            ], 
            "id": "#awe_qc.tool.yaml"
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
                    "id": "#main/assembled"
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
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#main/qc_kmers"
                }, 
                {
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#main/qc_out_prefix"
                }, 
                {
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "default": "8", 
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
            "outputs": [
                {
                    "type": "File", 
                    "outputSource": "#main/preprocess/passed", 
                    "id": "#main/out"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/preprocess/removed", 
                    "id": "#main/removed"
                }
            ], 
            "steps": [
                {
                    "run": "#awe_preprocess.tool.yaml", 
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
                            "valueFrom": "$(inputs.jobid).100.preprocess", 
                            "id": "#main/preprocess/out_prefix"
                        }
                    ], 
                    "out": [
                        "#main/preprocess/removed", 
                        "#main/preprocess/passed"
                    ], 
                    "id": "#main/preprocess"
                }, 
                {
                    "run": "#awe_qc.tool.yaml", 
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
                            "valueFrom": "$(inputs.jobid).075", 
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
                    ], 
                    "out": [
                        "#main/qc/assembly", 
                        "#main/qc/qcstats", 
                        "#main/qc/uploadstats"
                    ], 
                    "id": "#main/qc"
                }
            ], 
            "id": "#main"
        }
    ]
}