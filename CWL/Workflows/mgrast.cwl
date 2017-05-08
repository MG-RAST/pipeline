{
    "cwlVersion": "v1.0", 
    "$graph": [
        {
            "inputs": [
                {
                    "default": "1", 
                    "type": "string", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/ach_sequence_ver"
                }, 
                {
                    "default": "1", 
                    "inputBinding": {
                        "prefix": "-ach_ver"
                    }, 
                    "type": "string", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/ach_ver"
                }, 
                {
                    "default": "/mnt/awe/data/predata/m5nr_v1.bdb", 
                    "inputBinding": {
                        "prefix": "-ann_file"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/ann_file"
                }, 
                {
                    "type": [
                        {
                            "fields": [
                                {
                                    "inputBinding": {
                                        "prefix": "-rna"
                                    }, 
                                    "type": "boolean", 
                                    "name": "#mg_annotate_aa_sims.tool.yaml/exclusive_parameters/RNA/rna"
                                }
                            ], 
                            "type": "record", 
                            "name": "#mg_annotate_aa_sims.tool.yaml/exclusive_parameters/RNA"
                        }, 
                        {
                            "fields": [
                                {
                                    "inputBinding": {
                                        "prefix": "-aa"
                                    }, 
                                    "type": "boolean", 
                                    "name": "#mg_annotate_aa_sims.tool.yaml/exclusive_parameters/AA/aa"
                                }
                            ], 
                            "type": "record", 
                            "name": "#mg_annotate_aa_sims.tool.yaml/exclusive_parameters/AA"
                        }
                    ], 
                    "id": "#mg_annotate_aa_sims.tool.yaml/exclusive_parameters"
                }, 
                {
                    "inputBinding": {
                        "position": 2, 
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/input"
                }, 
                {
                    "default": "annotate_sims", 
                    "inputBinding": {
                        "position": 1, 
                        "prefix": "-out_prefix"
                    }, 
                    "type": "string", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/out_prefix"
                }, 
                {
                    "default": false, 
                    "inputBinding": {
                        "prefix": "-help"
                    }, 
                    "type": "boolean", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/tool_help"
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        {
                            "entry": "{\n    \"stage_id\": \"650\",\n    \"stage_name\": \"protein.sims\",\n    \"m5nr_sims_version\": \"$(inputs.ach_sequence_ver)\",\n    \"m5nr_annotation_version\": \"$(inputs.ach_ver)\"\n}\n", 
                            "entryname": "userattr.json"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).aa.sims.filter"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/filter"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).aa.sims.filter.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/filterattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).aa.expand.lca"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/lca"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).aa.expand.lca.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/lcarattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).aa.expand.ontology"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/ontology"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).aa.expand.ontology.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/ontologyattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).aa.expand.protein"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/protein"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).aa.expand.protein.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_aa_sims.tool.yaml/proteinattr"
                }
            ], 
            "baseCommand": "mg_annotate_sims.pl", 
            "class": "CommandLineTool", 
            "label": "aa sims annotation", 
            "id": "#mg_annotate_aa_sims.tool.yaml"
        }, 
        {
            "inputs": [
                {
                    "default": "1", 
                    "type": "string", 
                    "id": "#mg_annotate_rna_sims.tool.yaml/ach_sequence_ver"
                }, 
                {
                    "default": "1", 
                    "inputBinding": {
                        "prefix": "-ach_ver"
                    }, 
                    "type": "string", 
                    "id": "#mg_annotate_rna_sims.tool.yaml/ach_ver"
                }, 
                {
                    "default": "./m5nr_v1.bdb", 
                    "inputBinding": {
                        "prefix": "-ann_file"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_rna_sims.tool.yaml/ann_file"
                }, 
                {
                    "inputBinding": {
                        "position": 2, 
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_rna_sims.tool.yaml/input"
                }, 
                {
                    "default": "annotate_sims", 
                    "inputBinding": {
                        "position": 1, 
                        "prefix": "-out_prefix"
                    }, 
                    "type": "string", 
                    "id": "#mg_annotate_rna_sims.tool.yaml/out_prefix"
                }, 
                {
                    "default": false, 
                    "inputBinding": {
                        "prefix": "-help"
                    }, 
                    "type": "boolean", 
                    "id": "#mg_annotate_rna_sims.tool.yaml/tool_help"
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        {
                            "entry": "{\n    \"stage_id\": \"450\",\n    \"stage_name\": \"rna.sims\",\n    \"m5rna_sims_version\": \"$(inputs.ach_sequence_ver)\",\n    \"m5rna_annotation_version\": \"$(inputs.ach_ver)\"\n}\n", 
                            "entryname": "userattr.json"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).rna.expand.rna"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_rna_sims.tool.yaml/feature"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).*.expand.rna.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_rna_sims.tool.yaml/featureattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).*.sims.filter"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_rna_sims.tool.yaml/filter"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).*.sims.filter.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_rna_sims.tool.yaml/filterattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).*.expand.lca"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_rna_sims.tool.yaml/lca"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).*.expand.lca.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_rna_sims.tool.yaml/lcarattr"
                }
            ], 
            "baseCommand": [
                "mg_annotate_sims.pl", 
                "--rna"
            ], 
            "class": "CommandLineTool", 
            "label": "rna sims annotation", 
            "id": "#mg_annotate_rna_sims.tool.yaml"
        }, 
        {
            "inputs": [
                {
                    "doc": "<md5|ontology|function|organism|source|lca>", 
                    "inputBinding": {
                        "prefix": "-type"
                    }, 
                    "type": "string", 
                    "id": "#mg_annotate_summary.tool.yaml/abundanceType"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-in_assemb"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#mg_annotate_summary.tool.yaml/in_assemb"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-in_expand"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#mg_annotate_summary.tool.yaml/in_expand"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-in_index"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#mg_annotate_summary.tool.yaml/in_index"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-in_maps"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#mg_annotate_summary.tool.yaml/in_maps"
                }, 
                {
                    "type": "string", 
                    "id": "#mg_annotate_summary.tool.yaml/nr_version"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-output"
                    }, 
                    "type": "string", 
                    "id": "#mg_annotate_summary.tool.yaml/output"
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        {
                            "entry": "{\n  \"stage_id\": \"700\",\n  \"stage_name\": \"annotation.summary\",\n  \"m5nr_annotation_version\": $(inputs.nr_version),\n  \"m5rna_annotation_version\": $(inputs.nr_version),\n  \"file_format\": \"abundance table\",\n  \"data_type\": $(inputs.abundanceType)\n}\n", 
                            "entryname": "userattr.json"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.output)"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_summary.tool.yaml/abundance"
                }, 
                {
                    "outputBinding": {
                        "glob": "userattr.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_annotate_summary.tool.yaml/abundanceattr"
                }
            ], 
            "class": "CommandLineTool", 
            "baseCommand": "mg_annotate_summary.pl", 
            "label": "abundance files", 
            "id": "#mg_annotate_summary.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/annotate:1.0", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "inputBinding": {
                        "prefix": "-i"
                    }, 
                    "type": "File", 
                    "id": "#mg_blat_protein.tool.yaml/input"
                }, 
                {
                    "doc": "Directory containing the db with prefix nr_prefix", 
                    "type": "Directory", 
                    "id": "#mg_blat_protein.tool.yaml/nr_dir"
                }, 
                {
                    "doc": "Filename prefix has to match nr_prefix", 
                    "type": "File", 
                    "id": "#mg_blat_protein.tool.yaml/nr_part_1"
                }, 
                {
                    "doc": "Filename prefix has to match nr_prefix", 
                    "type": "File", 
                    "id": "#mg_blat_protein.tool.yaml/nr_part_2"
                }, 
                {
                    "default": "md5nr", 
                    "doc": "prefix for nr, expects *.1 and *.2", 
                    "type": "string", 
                    "id": "#mg_blat_protein.tool.yaml/nr_prefix"
                }, 
                {
                    "type": "string", 
                    "id": "#mg_blat_protein.tool.yaml/nr_version"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-o"
                    }, 
                    "type": "string", 
                    "id": "#mg_blat_protein.tool.yaml/output"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-d"
                    }, 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#mg_blat_protein.tool.yaml/sort_dir"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }, 
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        "$(inputs.nr_part_1)", 
                        "$(inputs.nr_part_2)", 
                        {
                            "entry": "{\n  \"stage_id\": \"650\",\n  \"stage_name\": \"protein.sims\",\n  \"m5nr_sims_version\": $(inputs.nr_version)\",\n  \"data_type\": \"similarity\",\n  \"file_format\": \"blast m8\",\n  \"sim_type\": \"protein\"\n}\n", 
                            "entryname": "userattr.json"
                        }
                    ]
                }
            ], 
            "stdout": "out.log", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#mg_blat_protein.tool.yaml/error"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.output)"
                    }, 
                    "type": "File", 
                    "id": "#mg_blat_protein.tool.yaml/sims"
                }, 
                {
                    "type": "stdout", 
                    "id": "#mg_blat_protein.tool.yaml/stdout"
                }
            ], 
            "class": "CommandLineTool", 
            "baseCommand": "mg_blat_prot.py", 
            "label": "aa sims blat", 
            "stderr": "error.log", 
            "id": "#mg_blat_protein.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:cwl", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "default": false, 
                    "inputBinding": {
                        "prefix": "-assembled"
                    }, 
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "id": "#mg_blat_rna.tool.yaml/assembled"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#mg_blat_rna.tool.yaml/input"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-output"
                    }, 
                    "type": "string", 
                    "id": "#mg_blat_rna.tool.yaml/output"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-rna_nr"
                    }, 
                    "type": "File", 
                    "id": "#mg_blat_rna.tool.yaml/rna_nr"
                }, 
                {
                    "type": "string", 
                    "id": "#mg_blat_rna.tool.yaml/rna_nr_version"
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        {
                            "entry": "{\n  \"stage_id\": \"450\",\n  \"stage_name\": \"rna.sims\",\n  \"m5rna_sims_version\": \"$(inputs.rna_nr_version)\",\n  \"data_type\": \"similarity\",\n  \"file_format\": \"blast m8\",\n  \"sim_type\": \"rna\"\n}\n", 
                            "entryname": "userattr.json"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.output)"
                    }, 
                    "type": "File", 
                    "id": "#mg_blat_rna.tool.yaml/sims"
                }, 
                {
                    "outputBinding": {
                        "glob": "userattr.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_blat_rna.tool.yaml/userattr"
                }
            ], 
            "class": "CommandLineTool", 
            "baseCommand": "mg_blat_rna.pl", 
            "label": "rna sims blat", 
            "id": "#mg_blat_rna.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:cwl", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "default": 1, 
                    "inputBinding": {
                        "prefix": "-bowtie"
                    }, 
                    "type": "int", 
                    "id": "#mg_bowtie_screen.tool.yaml/bowtie"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-index"
                    }, 
                    "type": "string", 
                    "id": "#mg_bowtie_screen.tool.yaml/index"
                }, 
                {
                    "type": "Directory", 
                    "id": "#mg_bowtie_screen.tool.yaml/indexDir"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#mg_bowtie_screen.tool.yaml/input"
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
                    "id": "#mg_bowtie_screen.tool.yaml/no-shock"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-output"
                    }, 
                    "type": "string", 
                    "id": "#mg_bowtie_screen.tool.yaml/output"
                }, 
                {
                    "default": 8, 
                    "inputBinding": {
                        "prefix": "-proc"
                    }, 
                    "type": "int", 
                    "id": "#mg_bowtie_screen.tool.yaml/proc"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }, 
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": "${\n  var listing = inputs.indexDir.listing;\n  listing.push(inputs.input);\n  return listing;\n }\n"
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.output)"
                    }, 
                    "type": "File", 
                    "id": "#mg_bowtie_screen.tool.yaml/passed"
                }, 
                {
                    "outputBinding": {
                        "glob": "userattr.json"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#mg_bowtie_screen.tool.yaml/passedAttr"
                }
            ], 
            "baseCommand": "mg_bowtie_screen.pl", 
            "class": "CommandLineTool", 
            "id": "#mg_bowtie_screen.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/bowtie_screen:1.0", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "type": [
                        {
                            "fields": [
                                {
                                    "inputBinding": {
                                        "prefix": "-rna"
                                    }, 
                                    "type": "boolean", 
                                    "name": "#mg_cluster.tool.yaml/exclusive_parameters/RNA/rna"
                                }
                            ], 
                            "type": "record", 
                            "name": "#mg_cluster.tool.yaml/exclusive_parameters/RNA"
                        }, 
                        {
                            "fields": [
                                {
                                    "inputBinding": {
                                        "prefix": "-dna"
                                    }, 
                                    "type": "boolean", 
                                    "name": "#mg_cluster.tool.yaml/exclusive_parameters/DNA/dna"
                                }
                            ], 
                            "type": "record", 
                            "name": "#mg_cluster.tool.yaml/exclusive_parameters/DNA"
                        }
                    ], 
                    "id": "#mg_cluster.tool.yaml/exclusive_parameters"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#mg_cluster.tool.yaml/input"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-memory"
                    }, 
                    "type": "int", 
                    "id": "#mg_cluster.tool.yaml/memory"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "type": "string", 
                    "id": "#mg_cluster.tool.yaml/out_prefix"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-pid"
                    }, 
                    "type": "int", 
                    "id": "#mg_cluster.tool.yaml/pid"
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        {
                            "entry": "{\n  \"stage_id\": \"440\",\n  \"stage_name\": \"rna.cluster\",\n  \"seq_format\": \"aa\",\n  \"cluster_percent\": \"$(inputs.pid)\"\n}\n", 
                            "entryname": "userattr.json"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).*.fna"
                    }, 
                    "type": "File", 
                    "id": "#mg_cluster.tool.yaml/fasta"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).*.fna.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_cluster.tool.yaml/fasta_userattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).*.mapping"
                    }, 
                    "type": "File", 
                    "id": "#mg_cluster.tool.yaml/mapping"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).*.mapping.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_cluster.tool.yaml/mapping_userattr"
                }
            ], 
            "class": "CommandLineTool", 
            "baseCommand": "mg_cluster.pl", 
            "label": "rna clustering", 
            "id": "#mg_cluster.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:cwl", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "inputBinding": {
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#mg_cluster_aa.tool.yaml/input"
                }, 
                {
                    "default": 20, 
                    "inputBinding": {
                        "prefix": "-memory"
                    }, 
                    "type": "int", 
                    "id": "#mg_cluster_aa.tool.yaml/memory"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "type": "string", 
                    "id": "#mg_cluster_aa.tool.yaml/out_prefix"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-pid"
                    }, 
                    "type": "int", 
                    "id": "#mg_cluster_aa.tool.yaml/pid"
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        {
                            "entry": "{\n \"stage_id\": \"550\",\n  \"stage_name\": \"protein.cluster\",\n  \"seq_format\": \"aa\",\n  \"cluster_percent\": \"$(inputs.pid)\"\n}\n", 
                            "entryname": "userattr.json"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).*.faa"
                    }, 
                    "type": "File", 
                    "id": "#mg_cluster_aa.tool.yaml/fasta"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).*.faa.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_cluster_aa.tool.yaml/fasta_userattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).*.mapping"
                    }, 
                    "type": "File", 
                    "id": "#mg_cluster_aa.tool.yaml/mapping"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).*.mapping.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_cluster_aa.tool.yaml/mapping_userattr"
                }
            ], 
            "class": "CommandLineTool", 
            "baseCommand": [
                "mg_cluster.pl", 
                "-aa"
            ], 
            "label": "aa clustering", 
            "id": "#mg_cluster_aa.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:cwl", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "default": 1, 
                    "inputBinding": {
                        "prefix": "-dereplicate"
                    }, 
                    "type": "int", 
                    "id": "#mg_dereplicate.tool.yaml/dereplicate"
                }, 
                {
                    "inputBinding": {
                        "valueFrom": "$(self.basename)", 
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#mg_dereplicate.tool.yaml/input"
                }, 
                {
                    "default": 16, 
                    "inputBinding": {
                        "prefix": "-memory"
                    }, 
                    "type": "int", 
                    "id": "#mg_dereplicate.tool.yaml/memory"
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
                    "id": "#mg_dereplicate.tool.yaml/no-shock"
                }, 
                {
                    "default": "derep", 
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "type": "string", 
                    "id": "#mg_dereplicate.tool.yaml/out_prefix"
                }, 
                {
                    "default": 50, 
                    "inputBinding": {
                        "prefix": "-prefix_length"
                    }, 
                    "type": "int", 
                    "id": "#mg_dereplicate.tool.yaml/prefix_length"
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
                    "id": "#mg_dereplicate.tool.yaml/attributes"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).passed.fna"
                    }, 
                    "type": "File", 
                    "id": "#mg_dereplicate.tool.yaml/passed"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).removed.fna"
                    }, 
                    "type": "File", 
                    "id": "#mg_dereplicate.tool.yaml/removed"
                }
            ], 
            "baseCommand": "mg_dereplicate.pl", 
            "class": "CommandLineTool", 
            "id": "#mg_dereplicate.tool.yaml", 
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
                    "inputBinding": {
                        "prefix": "-in_clust"
                    }, 
                    "type": "File", 
                    "id": "#mg_filter_feature.tool.yaml/in_clust"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-in_seq"
                    }, 
                    "type": "File", 
                    "id": "#mg_filter_feature.tool.yaml/in_seq"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-in_sim"
                    }, 
                    "type": "File", 
                    "id": "#mg_filter_feature.tool.yaml/in_sim"
                }, 
                {
                    "default": 8, 
                    "inputBinding": {
                        "prefix": "-memory"
                    }, 
                    "type": "int", 
                    "id": "#mg_filter_feature.tool.yaml/memory"
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
                    "id": "#mg_filter_feature.tool.yaml/no-shock"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-output"
                    }, 
                    "type": "string", 
                    "id": "#mg_filter_feature.tool.yaml/output"
                }, 
                {
                    "default": 10, 
                    "inputBinding": {
                        "prefix": "-overlap"
                    }, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#mg_filter_feature.tool.yaml/overlap"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-help"
                    }, 
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "id": "#mg_filter_feature.tool.yaml/tool_help"
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        {
                            "entry": "{\n  \"stage_id\": \"375\",\n  \"stage_name\": \"filtering\",\n  \"data_type\": \"sequence\",\n  \"file_format\": \"fasta\",\n  \"seq_format\": \"aa\",\n  \"overlap\": \"$(inputs.overlap)\"\n}\n", 
                            "entryname": "userattr.json"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.output)"
                    }, 
                    "type": "File", 
                    "id": "#mg_filter_feature.tool.yaml/filtered"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.output).json"
                    }, 
                    "type": "File", 
                    "id": "#mg_filter_feature.tool.yaml/userattr"
                }
            ], 
            "class": "CommandLineTool", 
            "baseCommand": "mg_filter_feature.pl", 
            "label": "aa filtering", 
            "id": "#mg_filter_feature.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:cwl", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "inputBinding": {
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#mg_genecalling.tool.yaml/input"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "type": "string", 
                    "id": "#mg_genecalling.tool.yaml/out_prefix"
                }, 
                {
                    "default": 8, 
                    "inputBinding": {
                        "prefix": "-proc"
                    }, 
                    "type": "int", 
                    "id": "#mg_genecalling.tool.yaml/proc"
                }, 
                {
                    "default": 100, 
                    "inputBinding": {
                        "prefix": "-size"
                    }, 
                    "type": "int", 
                    "id": "#mg_genecalling.tool.yaml/size"
                }, 
                {
                    "doc": "<sanger|454|illumina|complete>", 
                    "inputBinding": {
                        "prefix": "-type"
                    }, 
                    "type": "string", 
                    "id": "#mg_genecalling.tool.yaml/type"
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        {
                            "entry": "{\n   \"stage_id\": \"350\",\n   \"stage_name\": \"genecalling\",\n   \"data_type\": \"sequence\",\n   \"file_format\": \"fasta\",\n   \"seq_format\": \"aa\",\n   \"fgs_type\": \"$(inputs.type)\"\n}\n", 
                            "entryname": "userattr.json"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).faa"
                    }, 
                    "type": "File", 
                    "id": "#mg_genecalling.tool.yaml/faa"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).fna"
                    }, 
                    "type": "File", 
                    "id": "#mg_genecalling.tool.yaml/fna"
                }, 
                {
                    "outputBinding": {
                        "glob": "userattr.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_genecalling.tool.yaml/userattr"
                }
            ], 
            "class": "CommandLineTool", 
            "baseCommand": "mg_genecalling.pl", 
            "label": "genecalling", 
            "id": "#mg_genecalling.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:cwl", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "inputBinding": {
                        "prefix": "-in_maps"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#mg_index_sim_seq.tool.yaml/in_maps"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-in_seqs"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#mg_index_sim_seq.tool.yaml/in_seqs"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-in_sims"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#mg_index_sim_seq.tool.yaml/in_sims"
                }, 
                {
                    "type": "string", 
                    "id": "#mg_index_sim_seq.tool.yaml/m5nr_version"
                }, 
                {
                    "default": 10, 
                    "inputBinding": {
                        "prefix": "-memory"
                    }, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#mg_index_sim_seq.tool.yaml/memory"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-output"
                    }, 
                    "type": "string", 
                    "id": "#mg_index_sim_seq.tool.yaml/output"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }, 
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": "${\n  var listing = inputs.in_seqs;\n  listing.concat(inputs.in_maps);\n  listing.concat(inputs.in_sims);\n  return listing;\n }\n \n"
                }
            ], 
            "stdout": "index_sim.out.log", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#mg_index_sim_seq.tool.yaml/error"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.output).index"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#mg_index_sim_seq.tool.yaml/index"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.output)"
                    }, 
                    "type": "File", 
                    "id": "#mg_index_sim_seq.tool.yaml/sims"
                }, 
                {
                    "type": "stdout", 
                    "id": "#mg_index_sim_seq.tool.yaml/stdout"
                }
            ], 
            "baseCommand": "mg_index_sim_seq.pl", 
            "class": "CommandLineTool", 
            "stderr": "index_sim.error.log", 
            "id": "#mg_index_sim_seq.tool.yaml"
        }, 
        {
            "inputs": [
                {
                    "inputBinding": {
                        "prefix": "-ann_ver"
                    }, 
                    "type": "string", 
                    "id": "#mg_load_cass.tool.yaml/ann_ver"
                }, 
                {
                    "default": "", 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#mg_load_cass.tool.yaml/api_key"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-api_url"
                    }, 
                    "type": "string", 
                    "id": "#mg_load_cass.tool.yaml/api_url"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-job"
                    }, 
                    "type": "int", 
                    "id": "#mg_load_cass.tool.yaml/job"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-lca"
                    }, 
                    "type": "File", 
                    "id": "#mg_load_cass.tool.yaml/lca"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-md5"
                    }, 
                    "type": "File", 
                    "id": "#mg_load_cass.tool.yaml/md5"
                }
            ], 
            "requirements": [
                {
                    "envDef": [
                        {
                            "envName": "MGRAST_WEBKEY", 
                            "envValue": "$(inputs.api_key)"
                        }
                    ], 
                    "class": "EnvVarRequirement"
                }
            ], 
            "stdout": "cassandra_load.log", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#mg_load_cass.tool.yaml/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#mg_load_cass.tool.yaml/log"
                }
            ], 
            "baseCommand": "mg_load_cass.pl", 
            "class": "CommandLineTool", 
            "stderr": "cassandra_load.error", 
            "id": "#mg_load_cass.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/dbload:1.0", 
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
                    "id": "#mg_preprocess.tool.yaml/filter_options"
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
                    "id": "#mg_preprocess.tool.yaml/format"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#mg_preprocess.tool.yaml/input"
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
                    "id": "#mg_preprocess.tool.yaml/no-shock"
                }, 
                {
                    "default": "prep", 
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "type": "string", 
                    "id": "#mg_preprocess.tool.yaml/out_prefix"
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
                    "id": "#mg_preprocess.tool.yaml/attributes"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).passed.fna"
                    }, 
                    "type": "File", 
                    "id": "#mg_preprocess.tool.yaml/passed"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).removed.fna"
                    }, 
                    "type": "File", 
                    "id": "#mg_preprocess.tool.yaml/removed"
                }
            ], 
            "baseCommand": "mg_preprocess.pl", 
            "class": "CommandLineTool", 
            "id": "#mg_preprocess.tool.yaml", 
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
                    "id": "#mg_qc.tool.yaml/assembled"
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
                    "id": "#mg_qc.tool.yaml/filter_options"
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
                    "id": "#mg_qc.tool.yaml/format"
                }, 
                {
                    "default": "15,6", 
                    "inputBinding": {
                        "prefix": "-kmers"
                    }, 
                    "type": "string", 
                    "id": "#mg_qc.tool.yaml/kmers"
                }, 
                {
                    "default": "qc", 
                    "inputBinding": {
                        "prefix": "-out_prefix"
                    }, 
                    "type": "string", 
                    "id": "#mg_qc.tool.yaml/out_prefix"
                }, 
                {
                    "default": 8, 
                    "inputBinding": {
                        "prefix": "-proc"
                    }, 
                    "type": "int", 
                    "id": "#mg_qc.tool.yaml/proc"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#mg_qc.tool.yaml/seqfile"
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
                    "id": "#mg_qc.tool.yaml/assembly"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).assembly.coverage.json"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#mg_qc.tool.yaml/assemblyattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).consensus.stats"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#mg_qc.tool.yaml/consensus"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).consensus.stats.json"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#mg_qc.tool.yaml/consensusattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).drisee.stats"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#mg_qc.tool.yaml/drisee"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).drisee.stats.json"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#mg_qc.tool.yaml/driseeattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).drisee.info"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#mg_qc.tool.yaml/driseeinfo"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).drisee.info.json"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#mg_qc.tool.yaml/driseeinfoattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).kmer.*.stats"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#mg_qc.tool.yaml/kmer"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).kmer.*.stats.json"
                    }, 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#mg_qc.tool.yaml/kmerattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).qc.stats"
                    }, 
                    "type": "File", 
                    "id": "#mg_qc.tool.yaml/qcstats"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).qc.stats.json"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#mg_qc.tool.yaml/qcstatsattr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).upload.stats"
                    }, 
                    "type": "File", 
                    "id": "#mg_qc.tool.yaml/uploadstats"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.out_prefix).upload.stats.json"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#mg_qc.tool.yaml/uploadstatsattr"
                }
            ], 
            "baseCommand": "mg_qc.pl", 
            "class": "CommandLineTool", 
            "id": "#mg_qc.tool.yaml", 
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
                    "inputBinding": {
                        "prefix": "-input", 
                        "valueFrom": "$(inputs.input.basename)"
                    }, 
                    "type": "File", 
                    "id": "#mg_search_rna.tool.yaml/input"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-output"
                    }, 
                    "type": "string", 
                    "id": "#mg_search_rna.tool.yaml/output"
                }, 
                {
                    "default": 8, 
                    "inputBinding": {
                        "prefix": "-proc"
                    }, 
                    "type": "int", 
                    "id": "#mg_search_rna.tool.yaml/proc"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-rna_nr"
                    }, 
                    "type": "File", 
                    "id": "#mg_search_rna.tool.yaml/rna_nr"
                }, 
                {
                    "default": 100, 
                    "inputBinding": {
                        "prefix": "-size"
                    }, 
                    "type": "int", 
                    "id": "#mg_search_rna.tool.yaml/size"
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        {
                            "entry": "{\n      \"stage_id\": \"425\",\n      \"stage_name\": \"rna.filter\",\n      \"data_type\": \"sequence\",\n      \"file_format\": \"fasta\",\n      \"seq_format\": \"bp\" ,\n}\n", 
                            "entryname": "userattr.json"
                        }, 
                        {
                            "entry": "$(inputs.input)"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.output)"
                    }, 
                    "type": "File", 
                    "id": "#mg_search_rna.tool.yaml/rna"
                }, 
                {
                    "outputBinding": {
                        "glob": "userattr.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_search_rna.tool.yaml/userattr"
                }
            ], 
            "class": "CommandLineTool", 
            "baseCommand": [
                "mg_search_rna.pl"
            ], 
            "label": "rna detection", 
            "id": "#mg_search_rna.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/pipeline:cwl", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "inputBinding": {
                        "prefix": "-aa_clust"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/aa_clust"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-aa_map"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/aa_map"
                }, 
                {
                    "default": "", 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#mg_stats.tool.yaml/api_key"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-api_url"
                    }, 
                    "type": "string", 
                    "id": "#mg_stats.tool.yaml/api_url"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-filter"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/c"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-derep"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/derep"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-genecall"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/genecall"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-job"
                    }, 
                    "type": "int", 
                    "id": "#mg_stats.tool.yaml/job"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-m5nr_db"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/m5nr_db"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-md5_abund"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/md5_abund"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-ann_ver"
                    }, 
                    "type": "string", 
                    "id": "#mg_stats.tool.yaml/nr_aa_annotation_version"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-nr_ver"
                    }, 
                    "type": "string", 
                    "id": "#mg_stats.tool.yaml/nr_aa_sequence_version"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-ont_hier"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/ont_hier"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-ontol"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/ontol"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-post_qc"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/post_qc"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-preproc"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/preproc"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-qc"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/qc"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-rna_clust"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/rna_clust"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-rna_map"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/rna_map"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-search"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/search"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-source"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/source"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-taxa_hier"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/taxa_hier"
                }, 
                {
                    "inputBinding": {
                        "prefix": "-upload"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/upload"
                }
            ], 
            "requirements": [
                {
                    "envDef": [
                        {
                            "envName": "MGRAST_WEBKEY", 
                            "envValue": "$(inputs.api_key)"
                        }
                    ], 
                    "class": "EnvVarRequirement"
                }, 
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": [
                        {
                            "entry": "{\n  \"stage_id\": \"999\",\n  \"stage_name\": \"done\"\n}\n", 
                            "entryname": "userattr.json"
                        }, 
                        "$(inputs.m5nr_db)", 
                        "$(inputs.taxa_hier)", 
                        "$(inputs.ont_hier)"
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputBinding": {
                        "glob": "$(inputs.aa_clust).json"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/aaClustAttr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.aa_clust)"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/aaClustFile"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.aa_map).json"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/aaMapAttr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.aa_map)"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/aaMapFile"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.genecall).json"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/genecallAttr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.genecall)"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/genecallFile"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.rna_clust).json"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/rnaClustAttr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.rna_clust)"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/rnaClustFile"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.rna_map).json"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/rnaMapAttr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.rna_map)"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/rnaMapFile"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.post_qc).json"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/screenAttr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.post_qc)"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/screenFile"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.search).json"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/searchAttr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.search)"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/searchFile"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.job).statistics.json.attr"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/statisticsAttr"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.job).statistics.json"
                    }, 
                    "type": "File", 
                    "id": "#mg_stats.tool.yaml/statisticsFile"
                }
            ], 
            "baseCommand": "mg_stats.pl", 
            "class": "CommandLineTool", 
            "id": "#mg_stats.tool.yaml", 
            "hints": [
                {
                    "dockerPull": "mgrast/dbload:1.0", 
                    "class": "DockerRequirement"
                }
            ]
        }, 
        {
            "inputs": [
                {
                    "default": 20, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#main/aa_cluster_memory"
                }, 
                {
                    "default": 90, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#main/aa_cluster_pid"
                }, 
                {
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#main/api_key"
                }, 
                {
                    "type": "string", 
                    "id": "#main/api_url"
                }, 
                {
                    "type": "int", 
                    "id": "#main/assembled"
                }, 
                {
                    "type": "Directory", 
                    "id": "#main/db_dir"
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
                    "default": 8, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#main/ff_memory"
                }, 
                {
                    "default": 10, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#main/ff_overlap"
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
                    "type": "int", 
                    "id": "#main/memory_index_sims"
                }, 
                {
                    "type": "string", 
                    "id": "#main/mgid"
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
                    "type": "File", 
                    "id": "#main/nr_aa_ann_file"
                }, 
                {
                    "type": "string", 
                    "id": "#main/nr_aa_annotation_version"
                }, 
                {
                    "type": "string", 
                    "id": "#main/nr_aa_sequence_version"
                }, 
                {
                    "type": "Directory", 
                    "id": "#main/nr_dir"
                }, 
                {
                    "type": "File", 
                    "id": "#main/nr_ontology_hierachy"
                }, 
                {
                    "type": "File", 
                    "id": "#main/nr_part_1"
                }, 
                {
                    "type": "File", 
                    "id": "#main/nr_part_2"
                }, 
                {
                    "type": "string", 
                    "id": "#main/nr_prefix"
                }, 
                {
                    "type": "File", 
                    "id": "#main/nr_rna_ann_file"
                }, 
                {
                    "type": "string", 
                    "id": "#main/nr_rna_annotation_version"
                }, 
                {
                    "type": "string", 
                    "id": "#main/nr_rna_sequence_version"
                }, 
                {
                    "type": "File", 
                    "id": "#main/nr_taxa_hierarchy"
                }, 
                {
                    "type": "string", 
                    "id": "#main/nr_version"
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
                    "default": true, 
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "id": "#main/rna"
                }, 
                {
                    "type": "boolean", 
                    "id": "#main/rna_assembled"
                }, 
                {
                    "default": 20, 
                    "type": "int", 
                    "id": "#main/rna_clust_memory"
                }, 
                {
                    "type": "File", 
                    "id": "#main/rna_nr"
                }, 
                {
                    "type": "File", 
                    "id": "#main/rna_nr_clust"
                }, 
                {
                    "type": "string", 
                    "id": "#main/rna_nr_version"
                }, 
                {
                    "type": "int", 
                    "id": "#main/rna_pid"
                }, 
                {
                    "type": "int", 
                    "id": "#main/screen_bowtie"
                }, 
                {
                    "type": "string", 
                    "id": "#main/screen_index"
                }, 
                {
                    "type": "string", 
                    "id": "#main/seqformat"
                }, 
                {
                    "type": "File", 
                    "id": "#main/sequences"
                }, 
                {
                    "default": "illumina", 
                    "doc": "<sanger|454|illumina|complete>", 
                    "type": "string", 
                    "id": "#main/sequencing_method"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }, 
                {
                    "class": "MultipleInputFeatureRequirement"
                }, 
                {
                    "class": "StepInputExpressionRequirement"
                }
            ], 
            "outputs": [
                {
                    "outputSource": "#main/clusterAA/fasta", 
                    "type": "File", 
                    "id": "#main/clusterAAFile"
                }, 
                {
                    "outputSource": "#main/clusterAA/mapping", 
                    "type": "File", 
                    "id": "#main/clusterMappingFile"
                }, 
                {
                    "outputSource": "#main/dereplication/attributes", 
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#main/derepAttr"
                }, 
                {
                    "outputSource": "#main/filterRNA/filtered", 
                    "type": "File", 
                    "id": "#main/filterRNAFile"
                }, 
                {
                    "outputSource": "#main/genecalling/faa", 
                    "type": "File", 
                    "id": "#main/genecallsFaaFile"
                }, 
                {
                    "outputSource": "#main/genecalling/fna", 
                    "type": "File", 
                    "id": "#main/genecallsFnaFile"
                }, 
                {
                    "outputSource": "#main/indexSims/index", 
                    "type": "File", 
                    "id": "#main/indexedSimsFile"
                }, 
                {
                    "outputSource": "#main/annotateAA/protein", 
                    "type": "File", 
                    "id": "#main/proteinFile"
                }, 
                {
                    "outputSource": "#main/annotateAA/filter", 
                    "type": "File", 
                    "id": "#main/proteinFilterFile"
                }, 
                {
                    "outputSource": "#main/annotateAA/lca", 
                    "type": "File", 
                    "id": "#main/proteinLcaFile"
                }, 
                {
                    "outputSource": "#main/annotateAA/ontology", 
                    "type": "File", 
                    "id": "#main/proteinOntologyFile"
                }, 
                {
                    "outputSource": "#main/preprocess/passed", 
                    "type": "File", 
                    "id": "#main/qcPassedFile"
                }, 
                {
                    "outputSource": "#main/preprocess/removed", 
                    "type": "File", 
                    "id": "#main/qcRemovedFile"
                }, 
                {
                    "outputSource": "#main/clusterRNA/fasta", 
                    "type": "File", 
                    "id": "#main/rnaClusterFile"
                }, 
                {
                    "outputSource": "#main/annotateRNA/feature", 
                    "type": "File", 
                    "id": "#main/rnaFeatureFile"
                }, 
                {
                    "outputSource": "#main/searchRNA/rna", 
                    "type": "File", 
                    "id": "#main/rnaFile"
                }, 
                {
                    "outputSource": "#main/annotateRNA/filter", 
                    "type": "File", 
                    "id": "#main/rnaFilterFile"
                }, 
                {
                    "outputSource": "#main/annotateRNA/lca", 
                    "type": "File", 
                    "id": "#main/rnaLcaFile"
                }, 
                {
                    "outputSource": "#main/clusterRNA/mapping", 
                    "type": "File", 
                    "id": "#main/rnaMappingFile"
                }, 
                {
                    "outputSource": "#main/simsRNA/sims", 
                    "type": "File", 
                    "id": "#main/rnaSimsFile"
                }, 
                {
                    "outputSource": "#main/screen/passedAttr", 
                    "type": "File", 
                    "id": "#main/screenPassedAttr"
                }, 
                {
                    "outputSource": "#main/screen/passed", 
                    "type": "File", 
                    "id": "#main/screenPassedFile"
                }, 
                {
                    "outputSource": "#main/simsAA/sims", 
                    "type": "File", 
                    "id": "#main/simsAAFile"
                }
            ], 
            "id": "#main", 
            "steps": [
                {
                    "out": [
                        "#main/annotateAA/filter", 
                        "#main/annotateAA/protein", 
                        "#main/annotateAA/lca", 
                        "#main/annotateAA/ontology"
                    ], 
                    "run": "#mg_annotate_aa_sims.tool.yaml", 
                    "id": "#main/annotateAA", 
                    "in": [
                        {
                            "source": "#main/nr_aa_sequence_version", 
                            "id": "#main/annotateAA/ach_sequence_ver"
                        }, 
                        {
                            "source": "#main/nr_aa_annotation_version", 
                            "id": "#main/annotateAA/ach_ver"
                        }, 
                        {
                            "source": "#main/nr_aa_ann_file", 
                            "id": "#main/annotateAA/ann_file"
                        }, 
                        {
                            "valueFrom": "${ return { \"aa\": true }; }  \n              \n", 
                            "id": "#main/annotateAA/exclusive_parameters"
                        }, 
                        {
                            "source": "#main/simsAA/sims", 
                            "id": "#main/annotateAA/input"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).650", 
                            "id": "#main/annotateAA/out_prefix"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/annotateRNA/filter", 
                        "#main/annotateRNA/feature", 
                        "#main/annotateRNA/lca"
                    ], 
                    "run": "#mg_annotate_rna_sims.tool.yaml", 
                    "id": "#main/annotateRNA", 
                    "in": [
                        {
                            "source": "#main/nr_rna_sequence_version", 
                            "id": "#main/annotateRNA/ach_sequence_ver"
                        }, 
                        {
                            "source": "#main/nr_rna_annotation_version", 
                            "id": "#main/annotateRNA/ach_ver"
                        }, 
                        {
                            "source": "#main/nr_rna_ann_file", 
                            "id": "#main/annotateRNA/ann_file"
                        }, 
                        {
                            "source": "#main/simsRNA/sims", 
                            "id": "#main/annotateRNA/input"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).450", 
                            "id": "#main/annotateRNA/out_prefix"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/clusterAA/fasta", 
                        "#main/clusterAA/mapping"
                    ], 
                    "run": "#mg_cluster_aa.tool.yaml", 
                    "id": "#main/clusterAA", 
                    "in": [
                        {
                            "source": "#main/filterRNA/filtered", 
                            "id": "#main/clusterAA/input"
                        }, 
                        {
                            "source": "#main/aa_cluster_memory", 
                            "id": "#main/clusterAA/memory"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).550.cluster", 
                            "id": "#main/clusterAA/out_prefix"
                        }, 
                        {
                            "source": "#main/aa_cluster_pid", 
                            "id": "#main/clusterAA/pid"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/clusterRNA/fasta", 
                        "#main/clusterRNA/mapping"
                    ], 
                    "run": "#mg_cluster.tool.yaml", 
                    "id": "#main/clusterRNA", 
                    "in": [
                        {
                            "valueFrom": "${ return { \"rna\": true }; }\n", 
                            "id": "#main/clusterRNA/exclusive_parameters"
                        }, 
                        {
                            "source": "#main/searchRNA/rna", 
                            "id": "#main/clusterRNA/input"
                        }, 
                        {
                            "source": "#main/rna_clust_memory", 
                            "id": "#main/clusterRNA/memory"
                        }, 
                        {
                            "source": "#main/no-shock", 
                            "id": "#main/clusterRNA/no-shock"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).440.cluster", 
                            "id": "#main/clusterRNA/out_prefix"
                        }, 
                        {
                            "source": "#main/rna_pid", 
                            "id": "#main/clusterRNA/pid"
                        }
                    ]
                }, 
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
                    "run": "#mg_dereplicate.tool.yaml", 
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
                    "out": [
                        "#main/filterRNA/filtered"
                    ], 
                    "run": "#mg_filter_feature.tool.yaml", 
                    "id": "#main/filterRNA", 
                    "in": [
                        {
                            "source": "#main/clusterRNA/mapping", 
                            "id": "#main/filterRNA/in_clust"
                        }, 
                        {
                            "source": "#main/genecalling/faa", 
                            "id": "#main/filterRNA/in_seq"
                        }, 
                        {
                            "source": "#main/simsRNA/sims", 
                            "id": "#main/filterRNA/in_sim"
                        }, 
                        {
                            "source": "#main/ff_memory", 
                            "id": "#main/filterRNA/memory"
                        }, 
                        {
                            "source": "#main/no-shock", 
                            "id": "#main/filterRNA/no-shock"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).375.filtering.faa", 
                            "id": "#main/filterRNA/output"
                        }, 
                        {
                            "source": "#main/ff_overlap", 
                            "id": "#main/filterRNA/overlap"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/finalStats/statisticsFile", 
                        "#main/finalStats/statisticsAttr", 
                        "#main/finalStats/screenFile", 
                        "#main/finalStats/screenAttr", 
                        "#main/finalStats/searchFile", 
                        "#main/finalStats/searchAttr", 
                        "#main/finalStats/rnaClustFile", 
                        "#main/finalStats/rnaClustAttr", 
                        "#main/finalStats/rnaMapFile", 
                        "#main/finalStats/rnaMapAttr", 
                        "#main/finalStats/genecallFile", 
                        "#main/finalStats/genecallAttr", 
                        "#main/finalStats/aaClustFile", 
                        "#main/finalStats/aaClustAttr", 
                        "#main/finalStats/aaMapFile", 
                        "#main/finalStats/aaMapAttr"
                    ], 
                    "label": "done stage", 
                    "run": "#mg_stats.tool.yaml", 
                    "id": "#main/finalStats", 
                    "in": [
                        {
                            "source": "#main/clusterAA/fasta", 
                            "id": "#main/finalStats/aa_clust"
                        }, 
                        {
                            "source": "#main/clusterAA/mapping", 
                            "id": "#main/finalStats/aa_map"
                        }, 
                        {
                            "source": "#main/nr_aa_annotation_version", 
                            "id": "#main/finalStats/ann_ver"
                        }, 
                        {
                            "source": "#main/api_url", 
                            "id": "#main/finalStats/api_url"
                        }, 
                        {
                            "source": "#main/dereplication/removed", 
                            "id": "#main/finalStats/derep"
                        }, 
                        {
                            "source": "#main/indexSims/index", 
                            "id": "#main/finalStats/filter"
                        }, 
                        {
                            "source": "#main/genecalling/faa", 
                            "id": "#main/finalStats/genecall"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "id": "#main/finalStats/job"
                        }, 
                        {
                            "source": "#main/nr_aa_ann_file", 
                            "id": "#main/finalStats/m5nr_db"
                        }, 
                        {
                            "source": "#main/summaryMD5/abundance", 
                            "id": "#main/finalStats/md5_abund"
                        }, 
                        {
                            "source": "#main/nr_aa_sequence_version", 
                            "id": "#main/finalStats/nr_ver"
                        }, 
                        {
                            "source": "#main/nr_ontology_hierachy", 
                            "id": "#main/finalStats/ont_hier"
                        }, 
                        {
                            "source": "#main/annotateAA/ontology", 
                            "id": "#main/finalStats/ontol"
                        }, 
                        {
                            "source": "#main/screen/passed", 
                            "id": "#main/finalStats/post_qc"
                        }, 
                        {
                            "source": "#main/preprocess/passed", 
                            "id": "#main/finalStats/preproc"
                        }, 
                        {
                            "source": "#main/qc/qcstats", 
                            "id": "#main/finalStats/qc"
                        }, 
                        {
                            "source": "#main/clusterRNA/fasta", 
                            "id": "#main/finalStats/rna_clust"
                        }, 
                        {
                            "source": "#main/clusterRNA/mapping", 
                            "id": "#main/finalStats/rna_map"
                        }, 
                        {
                            "source": "#main/searchRNA/rna", 
                            "id": "#main/finalStats/search"
                        }, 
                        {
                            "source": "#main/summarySource/abundance", 
                            "id": "#main/finalStats/source"
                        }, 
                        {
                            "source": "#main/nr_taxa_hierarchy", 
                            "id": "#main/finalStats/taxa_hier"
                        }, 
                        {
                            "source": "#main/qc/uploadstats", 
                            "id": "#main/finalStats/upload"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/genecalling/fna", 
                        "#main/genecalling/faa"
                    ], 
                    "run": "#mg_genecalling.tool.yaml", 
                    "id": "#main/genecalling", 
                    "in": [
                        {
                            "source": "#main/screen/passed", 
                            "id": "#main/genecalling/input"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).350.genecalling.coding", 
                            "id": "#main/genecalling/out_prefix"
                        }, 
                        {
                            "source": "#main/sequencing_method", 
                            "id": "#main/genecalling/type"
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
                        "#main/indexSims/index"
                    ], 
                    "run": "#mg_index_sim_seq.tool.yaml", 
                    "id": "#main/indexSims", 
                    "in": [
                        {
                            "source": [
                                "#main/clusterAA/mapping", 
                                "#main/clusterRNA/mapping"
                            ], 
                            "id": "#main/indexSims/in_maps"
                        }, 
                        {
                            "source": [
                                "#main/genecalling/fna", 
                                "#main/searchRNA/rna"
                            ], 
                            "id": "#main/indexSims/in_seqs"
                        }, 
                        {
                            "source": [
                                "#main/annotateRNA/filter", 
                                "#main/annotateAA/filter"
                            ], 
                            "id": "#main/indexSims/in_sims"
                        }, 
                        {
                            "source": "#main/nr_aa_annotation_version", 
                            "id": "#main/indexSims/m5nr_version"
                        }, 
                        {
                            "source": "#main/memory_index_sims", 
                            "id": "#main/indexSims/memory"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).700.annotation.sims.filter.seq", 
                            "id": "#main/indexSims/output"
                        }
                    ]
                }, 
                {
                    "requirements": [
                        {
                            "class": "InitialWorkDirRequirement", 
                            "listing": [
                                {
                                    "entry": "{\n  \"id\": \"$(inputs.mgid)\"\n}\n", 
                                    "entryname": "userattr.json"
                                }
                            ]
                        }
                    ], 
                    "label": "abundance cassandra load", 
                    "in": [
                        {
                            "source": "#main/nr_aa_annotation_version", 
                            "id": "#main/loadCass/ann_ver"
                        }, 
                        {
                            "source": "#main/api_key", 
                            "id": "#main/loadCass/api_key"
                        }, 
                        {
                            "source": "#main/api_url", 
                            "id": "#main/loadCass/api_url"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "id": "#main/loadCass/job"
                        }, 
                        {
                            "source": "#main/summaryLCA/abundance", 
                            "id": "#main/loadCass/lca"
                        }, 
                        {
                            "source": "#main/summaryMD5/abundance", 
                            "id": "#main/loadCass/md5"
                        }, 
                        {
                            "source": "#main/mgid", 
                            "id": "#main/loadCass/mgid"
                        }
                    ], 
                    "run": "#mg_load_cass.tool.yaml", 
                    "id": "#main/loadCass", 
                    "out": [
                        "#main/loadCass/log", 
                        "#main/loadCass/error"
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
                    "run": "#mg_preprocess.tool.yaml", 
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
                    "run": "#mg_qc.tool.yaml", 
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
                }, 
                {
                    "requirements": [
                        {
                            "class": "InitialWorkDirRequirement", 
                            "listing": [
                                {
                                    "entry": "{\n  \"stage_id\": \"299\",\n  \"stage_name\": \"screen\",\n  \"data_type\": \"sequence\",\n  \"file_format\": \"fasta\",\n  \"seq_format\": \"bp\"\n}\n", 
                                    "entryname": "userattr.json"
                                }
                            ]
                        }
                    ], 
                    "out": [
                        "#main/screen/passed", 
                        "#main/screen/passedAttr"
                    ], 
                    "run": "#mg_bowtie_screen.tool.yaml", 
                    "id": "#main/screen", 
                    "in": [
                        {
                            "source": "#main/screen_bowtie", 
                            "id": "#main/screen/bowtie"
                        }, 
                        {
                            "source": "#main/screen_index", 
                            "id": "#main/screen/index"
                        }, 
                        {
                            "source": "#main/db_dir", 
                            "id": "#main/screen/indexDir"
                        }, 
                        {
                            "source": "#main/dereplication/passed", 
                            "id": "#main/screen/input"
                        }, 
                        {
                            "source": "#main/no-shock", 
                            "id": "#main/screen/no-shock"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).299.screen.passed.fna", 
                            "id": "#main/screen/output"
                        }, 
                        {
                            "source": "#main/qc_proc", 
                            "id": "#main/screen/proc"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/searchRNA/rna"
                    ], 
                    "run": "#mg_search_rna.tool.yaml", 
                    "id": "#main/searchRNA", 
                    "in": [
                        {
                            "source": "#main/preprocess/passed", 
                            "id": "#main/searchRNA/input"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).425.search.rna.fna", 
                            "id": "#main/searchRNA/output"
                        }, 
                        {
                            "source": "#main/rna_nr_clust", 
                            "id": "#main/searchRNA/rna_nr"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/simsAA/sims"
                    ], 
                    "run": "#mg_blat_protein.tool.yaml", 
                    "id": "#main/simsAA", 
                    "in": [
                        {
                            "source": "#main/clusterAA/fasta", 
                            "id": "#main/simsAA/input"
                        }, 
                        {
                            "source": "#main/nr_dir", 
                            "id": "#main/simsAA/nr_dir"
                        }, 
                        {
                            "source": "#main/nr_part_1", 
                            "id": "#main/simsAA/nr_part_1"
                        }, 
                        {
                            "source": "#main/nr_part_2", 
                            "id": "#main/simsAA/nr_part_2"
                        }, 
                        {
                            "source": "#main/nr_prefix", 
                            "id": "#main/simsAA/nr_prefix"
                        }, 
                        {
                            "source": "#main/nr_version", 
                            "id": "#main/simsAA/nr_version"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).650.superblat.sims", 
                            "id": "#main/simsAA/output"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/simsRNA/sims"
                    ], 
                    "run": "#mg_blat_rna.tool.yaml", 
                    "id": "#main/simsRNA", 
                    "in": [
                        {
                            "source": "#main/rna_assembled", 
                            "id": "#main/simsRNA/assembled"
                        }, 
                        {
                            "source": "#main/clusterRNA/fasta", 
                            "id": "#main/simsRNA/input"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).450.rna.sims", 
                            "id": "#main/simsRNA/output"
                        }, 
                        {
                            "source": "#main/rna_nr", 
                            "id": "#main/simsRNA/rna_nr"
                        }, 
                        {
                            "source": "#main/rna_nr_version", 
                            "id": "#main/simsRNA/rna_nr_version"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/summaryLCA/abundance"
                    ], 
                    "label": "lca abundance", 
                    "run": "#mg_annotate_summary.tool.yaml", 
                    "id": "#main/summaryLCA", 
                    "in": [
                        {
                            "default": "lca", 
                            "id": "#main/summaryLCA/abundanceType"
                        }, 
                        {
                            "source": "#main/qc/assembly", 
                            "id": "#main/summaryLCA/in_assemb"
                        }, 
                        {
                            "source": [
                                "#main/annotateAA/lca", 
                                "#main/annotateRNA/lca"
                            ], 
                            "id": "#main/summaryLCA/in_expand"
                        }, 
                        {
                            "source": [
                                "#main/clusterAA/mapping", 
                                "#main/clusterRNA/mapping"
                            ], 
                            "id": "#main/summaryLCA/in_maps"
                        }, 
                        {
                            "source": "#main/nr_aa_annotation_version", 
                            "id": "#main/summaryLCA/nr_version"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).700.annotation.lca.abundance", 
                            "id": "#main/summaryLCA/output"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/summaryMD5/abundance"
                    ], 
                    "label": "md5 abundance", 
                    "run": "#mg_annotate_summary.tool.yaml", 
                    "id": "#main/summaryMD5", 
                    "in": [
                        {
                            "default": "md5", 
                            "id": "#main/summaryMD5/abundanceType"
                        }, 
                        {
                            "source": "#main/qc/assembly", 
                            "id": "#main/summaryMD5/in_assemb"
                        }, 
                        {
                            "source": [
                                "#main/annotateAA/filter", 
                                "#main/annotateRNA/filter"
                            ], 
                            "id": "#main/summaryMD5/in_expand"
                        }, 
                        {
                            "source": "#main/indexSims/index", 
                            "id": "#main/summaryMD5/in_index"
                        }, 
                        {
                            "source": [
                                "#main/clusterAA/mapping", 
                                "#main/clusterRNA/mapping"
                            ], 
                            "id": "#main/summaryMD5/in_maps"
                        }, 
                        {
                            "source": "#main/nr_aa_annotation_version", 
                            "id": "#main/summaryMD5/nr_version"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).700.annotation.md5.abundance", 
                            "id": "#main/summaryMD5/output"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/summarySource/abundance"
                    ], 
                    "label": "source abundance", 
                    "run": "#mg_annotate_summary.tool.yaml", 
                    "id": "#main/summarySource", 
                    "in": [
                        {
                            "default": "source", 
                            "id": "#main/summarySource/abundanceType"
                        }, 
                        {
                            "source": "#main/qc/assembly", 
                            "id": "#main/summarySource/in_assemb"
                        }, 
                        {
                            "source": [
                                "#main/annotateAA/protein", 
                                "#main/annotateRNA/feature"
                            ], 
                            "id": "#main/summarySource/in_expand"
                        }, 
                        {
                            "source": [
                                "#main/clusterAA/mapping", 
                                "#main/clusterRNA/mapping"
                            ], 
                            "id": "#main/summarySource/in_maps"
                        }, 
                        {
                            "source": "#main/nr_aa_annotation_version", 
                            "id": "#main/summarySource/nr_version"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).700.annotation.source.stats", 
                            "id": "#main/summarySource/output"
                        }
                    ]
                }
            ], 
            "class": "Workflow"
        }
    ]
}
