{
    "cwlVersion": "v1.0", 
    "$graph": [
        {
            "inputs": [
                {
                    "inputBinding": {
                        "position": 1
                    }, 
                    "type": {
                        "items": "File", 
                        "inputBinding": {
                            "valueFrom": "$(self.basename)"
                        }, 
                        "type": "array"
                    }, 
                    "id": "#DynamicTrimmer.tool.cwl/sequences"
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": "$(inputs.sequences)"
                }, 
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "DynamicTrimmer.log", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#DynamicTrimmer.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#DynamicTrimmer.tool.cwl/info"
                }, 
                {
                    "outputBinding": {
                        "glob": "*.rejected.fastq"
                    }, 
                    "type": [
                        "File"
                    ], 
                    "id": "#DynamicTrimmer.tool.cwl/rejected", 
                    "format": "file:///Users/Andi/Development/MG-RAST-Repo/pipeline/CWL/Tools/fastq"
                }, 
                {
                    "outputBinding": {
                        "glob": "*.trimmed.fastq"
                    }, 
                    "type": [
                        "File"
                    ], 
                    "id": "#DynamicTrimmer.tool.cwl/trimmed", 
                    "format": "file:///Users/Andi/Development/MG-RAST-Repo/pipeline/CWL/Tools/fastq"
                }
            ], 
            "baseCommand": [
                "DynamicTrimmer.pl"
            ], 
            "class": "CommandLineTool", 
            "stderr": "DynamicTrimmer.error", 
            "$namespaces": {
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#DynamicTrimmer.tool.cwl", 
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
                    "doc": "Database fasta format file", 
                    "inputBinding": {
                        "position": 1
                    }, 
                    "type": "File", 
                    "id": "#blat.tool.cwl/database", 
                    "format": [
                        "#blat.tool.cwl/database/FileFormats.cv.yamlfasta"
                    ]
                }, 
                {
                    "doc": "Database type", 
                    "inputBinding": {
                        "prefix": "-t=", 
                        "separate": false
                    }, 
                    "type": "string", 
                    "id": "#blat.tool.cwl/dbType", 
                    "format": [
                        "#blat.tool.cwl/dbType/BlatTypes.cv.yamldna", 
                        "#blat.tool.cwl/dbType/BlatTypes.cv.yamlprot", 
                        "#blat.tool.cwl/dbType/BlatTypes.cv.yamldnax"
                    ]
                }, 
                {
                    "doc": "Run for fast DNA/DNA remapping - not allowing introns", 
                    "inputBinding": {
                        "prefix": "-fastMap"
                    }, 
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "id": "#blat.tool.cwl/fastMap"
                }, 
                {
                    "doc": "Output name", 
                    "inputBinding": {
                        "position": 3
                    }, 
                    "type": "string", 
                    "id": "#blat.tool.cwl/outName"
                }, 
                {
                    "doc": "Query fasta format file", 
                    "inputBinding": {
                        "position": 2
                    }, 
                    "type": "File", 
                    "id": "#blat.tool.cwl/query", 
                    "format": [
                        "#blat.tool.cwl/query/FileFormats.cv.yamlfasta"
                    ]
                }, 
                {
                    "doc": "Query type", 
                    "inputBinding": {
                        "prefix": "-q=", 
                        "separate": false
                    }, 
                    "type": "string", 
                    "id": "#blat.tool.cwl/queryType", 
                    "format": [
                        "#blat.tool.cwl/queryType/BlatTypes.cv.yamldna", 
                        "#blat.tool.cwl/queryType/BlatTypes.cv.yamlrna", 
                        "#blat.tool.cwl/queryType/BlatTypes.cv.yamlprot", 
                        "#blat.tool.cwl/queryType/BlatTypes.cv.yamldnax", 
                        "#blat.tool.cwl/queryType/BlatTypes.cv.yamlrnax"
                    ]
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "blat.log", 
            "doc": "fast sequence search command line tool\n>blat -fastMap -t dna -q rna -out blast8 <database> <query> <output>\n", 
            "class": "CommandLineTool", 
            "baseCommand": [
                "blat"
            ], 
            "label": "BLAT", 
            "arguments": [
                "-out=blast8"
            ], 
            "stderr": "blat.error", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#blat.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#blat.tool.cwl/info"
                }, 
                {
                    "doc": "Output tab separated similarity file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "type": "File", 
                    "id": "#blat.tool.cwl/output"
                }
            ], 
            "$namespaces": {
                "Types": "BlatTypes.cv.yaml", 
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#blat.tool.cwl", 
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
                    "default": 3, 
                    "doc": "Remove all evalues with an exponent lower than cutoff, default 3", 
                    "inputBinding": {
                        "prefix": "-c"
                    }, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#bleachsims.tool.cwl/cutoff"
                }, 
                {
                    "doc": "Input similarity blast-m8 file", 
                    "inputBinding": {
                        "prefix": "-s"
                    }, 
                    "type": "File", 
                    "id": "#bleachsims.tool.cwl/input", 
                    "format": [
                        "#bleachsims.tool.cwl/input/FileFormats.cv.yamltsv"
                    ]
                }, 
                {
                    "default": 20, 
                    "doc": "Minimum", 
                    "inputBinding": {
                        "prefix": "-m"
                    }, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#bleachsims.tool.cwl/min"
                }, 
                {
                    "doc": "Output name", 
                    "inputBinding": {
                        "prefix": "-o"
                    }, 
                    "type": "string", 
                    "id": "#bleachsims.tool.cwl/outName"
                }, 
                {
                    "default": 0, 
                    "doc": "Best evalue plus this exponent that will be returned, default 0 (no range)", 
                    "inputBinding": {
                        "prefix": "-r"
                    }, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#bleachsims.tool.cwl/range"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "bleachsims.log", 
            "doc": "filter similarity file by E-value and number of hits\n>bleachsims -s <input> -o <output> -m 20 -r 0 -c 3\n", 
            "class": "CommandLineTool", 
            "baseCommand": [
                "bleachsims"
            ], 
            "label": "bleachsims", 
            "stderr": "bleachsims.error", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#bleachsims.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#bleachsims.tool.cwl/info"
                }, 
                {
                    "doc": "Output filtered similarity blast-m8 file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "type": "File", 
                    "id": "#bleachsims.tool.cwl/output"
                }
            ], 
            "$namespaces": {
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#bleachsims.tool.cwl", 
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
                    "default": 0.97, 
                    "doc": "Percent identity threshold, default 0.97", 
                    "inputBinding": {
                        "prefix": "-c"
                    }, 
                    "type": [
                        "null", 
                        "float"
                    ], 
                    "id": "#cdhit-est.tool.cwl/identity"
                }, 
                {
                    "doc": "Input fasta format file", 
                    "inputBinding": {
                        "prefix": "-i"
                    }, 
                    "type": "File", 
                    "id": "#cdhit-est.tool.cwl/input", 
                    "format": [
                        "#cdhit-est.tool.cwl/input/FileFormats.cv.yamlfasta"
                    ]
                }, 
                {
                    "doc": "Output name", 
                    "inputBinding": {
                        "prefix": "-o"
                    }, 
                    "type": "string", 
                    "id": "#cdhit-est.tool.cwl/outName"
                }, 
                {
                    "default": 9, 
                    "doc": "Word length, default 9", 
                    "inputBinding": {
                        "prefix": "-n"
                    }, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#cdhit-est.tool.cwl/word"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "cdhit-est.log", 
            "doc": "cluster nucleotide sequences\nuse max available cpus and memory\n>cdhit-est -n 9 -d 0 -T 0 -M 0 -c 0.97 -i <input> -o <output>\n", 
            "class": "CommandLineTool", 
            "baseCommand": [
                "cdhit-est"
            ], 
            "label": "CD-HIT-est", 
            "arguments": [
                {
                    "prefix": "-M", 
                    "valueFrom": "0"
                }, 
                {
                    "prefix": "-T", 
                    "valueFrom": "0"
                }, 
                {
                    "prefix": "-d", 
                    "valueFrom": "0"
                }
            ], 
            "stderr": "cdhit-est.error", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#cdhit-est.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#cdhit-est.tool.cwl/info"
                }, 
                {
                    "doc": "Output cluster mapping file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName).clstr"
                    }, 
                    "type": "File", 
                    "id": "#cdhit-est.tool.cwl/outClstr"
                }, 
                {
                    "doc": "Output fasta format file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "type": "File", 
                    "id": "#cdhit-est.tool.cwl/outSeq"
                }
            ], 
            "$namespaces": {
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#cdhit-est.tool.cwl", 
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
                    "doc": "Input .clstr format file", 
                    "inputBinding": {
                        "prefix": "--input"
                    }, 
                    "type": "File", 
                    "id": "#format_cluster.tool.cwl/input"
                }, 
                {
                    "doc": "Output .mapping format file", 
                    "inputBinding": {
                        "prefix": "--output"
                    }, 
                    "type": "string", 
                    "id": "#format_cluster.tool.cwl/outName"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "format_cluster.log", 
            "doc": "re-formats cd-hit .clstr file into mg-rast .mapping file\n>format_cluster.pl --input <input> --output <output>\n", 
            "class": "CommandLineTool", 
            "baseCommand": [
                "format_cluster.pl"
            ], 
            "label": "cluster file reformat", 
            "stderr": "format_cluster.error", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#format_cluster.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#format_cluster.tool.cwl/info"
                }, 
                {
                    "doc": "Output .mapping format file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "type": "File", 
                    "id": "#format_cluster.tool.cwl/output"
                }
            ], 
            "$namespaces": {
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#format_cluster.tool.cwl", 
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
                    "doc": "Tab separated similarity file", 
                    "inputBinding": {
                        "prefix": "--sim"
                    }, 
                    "type": "File", 
                    "id": "#rna_feature.tool.cwl/aligned", 
                    "format": [
                        "#rna_feature.tool.cwl/aligned/FileFormats.cv.yamltsv"
                    ]
                }, 
                {
                    "default": 75, 
                    "doc": "Percent identity threshold, default 75", 
                    "inputBinding": {
                        "prefix": "--ident"
                    }, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#rna_feature.tool.cwl/identity"
                }, 
                {
                    "doc": "Output fasta format file", 
                    "inputBinding": {
                        "prefix": "--output"
                    }, 
                    "type": "string", 
                    "id": "#rna_feature.tool.cwl/outName"
                }, 
                {
                    "doc": "Tab separated sequence file", 
                    "inputBinding": {
                        "prefix": "--seq"
                    }, 
                    "type": "File", 
                    "id": "#rna_feature.tool.cwl/sequence", 
                    "format": [
                        "#rna_feature.tool.cwl/sequence/FileFormats.cv.yamltsv"
                    ]
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "rna_feature.log", 
            "doc": "identify rRNAs features from given rRNA fasta and blast aligned files\n>rna_feature.pl --seq <sequence> --sim <aligned> --ident 75 --output <output>\n", 
            "class": "CommandLineTool", 
            "baseCommand": [
                "rna_feature.pl"
            ], 
            "label": "rna features", 
            "stderr": "rna_feature.error", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#rna_feature.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#rna_feature.tool.cwl/info"
                }, 
                {
                    "doc": "Output fasta format file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "type": "File", 
                    "id": "#rna_feature.tool.cwl/output"
                }
            ], 
            "$namespaces": {
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#rna_feature.tool.cwl", 
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
                        "prefix": "--bowtie_truncate"
                    }, 
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "id": "#seqUtil.tool.cwl/bowtie_truncate"
                }, 
                {
                    "inputBinding": {
                        "prefix": "--fasta2tab"
                    }, 
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "id": "#seqUtil.tool.cwl/fasta2tab"
                }, 
                {
                    "inputBinding": {
                        "prefix": "--fastq2fasta"
                    }, 
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "id": "#seqUtil.tool.cwl/fastq2fasta"
                }, 
                {
                    "inputBinding": {
                        "prefix": "--output"
                    }, 
                    "type": "string", 
                    "id": "#seqUtil.tool.cwl/output"
                }, 
                {
                    "inputBinding": {
                        "prefix": "--input"
                    }, 
                    "type": "File", 
                    "id": "#seqUtil.tool.cwl/sequences", 
                    "format": [
                        "#seqUtil.tool.cwl/sequences/FileFormats.cv.yamlfastq", 
                        "#seqUtil.tool.cwl/sequences/FileFormats.cv.yamlfasta"
                    ]
                }, 
                {
                    "inputBinding": {
                        "prefix": "--sortbyid2tab"
                    }, 
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "id": "#seqUtil.tool.cwl/sortbyid2tab"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "seqUtil.log", 
            "doc": "Convert fastq into fasta and fasta into tab files.", 
            "class": "CommandLineTool", 
            "baseCommand": [
                "seqUtil"
            ], 
            "label": "seqUtil", 
            "arguments": [
                {
                    "prefix": null, 
                    "valueFrom": "${\n   if (  (\"format\" in inputs.sequences) && (inputs.sequences.format.split(\"/\").slice(-1)[0] == \"fastq\")  ) { return \"--fastq\"; } else { return \"\" ; }  \n }\n"
                }
            ], 
            "stderr": "seqUtil.error", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#seqUtil.tool.cwl/error"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.output)"
                    }, 
                    "type": "File", 
                    "id": "#seqUtil.tool.cwl/file", 
                    "format": "${\n  if (inputs.fasta2tab) \n      { return \"tsv\" ;}\n  else if (inputs.sortbyid2tab) \n      { return \"tsv\" ;}\n  else if (inputs.fastq2fasta) \n      { return \"fasta\";}\n  else if (inputs.sequences.format) \n      { return inputs.sequences.format ;}\n  else { return '' ;}\n  return \"\" ;\n}\n"
                }, 
                {
                    "type": "stdout", 
                    "id": "#seqUtil.tool.cwl/info"
                }
            ], 
            "$namespaces": {
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#seqUtil.tool.cwl", 
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
                    "doc": "Optional input file, cluster mapping", 
                    "inputBinding": {
                        "prefix": "--cluster"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#sims_abundance.tool.cwl/cluster"
                }, 
                {
                    "doc": "Optional input file, assembly coverage", 
                    "inputBinding": {
                        "prefix": "--coverage"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#sims_abundance.tool.cwl/coverage"
                }, 
                {
                    "doc": "Input expanded sims file", 
                    "inputBinding": {
                        "prefix": "-i"
                    }, 
                    "type": "File", 
                    "id": "#sims_abundance.tool.cwl/input", 
                    "format": [
                        "#sims_abundance.tool.cwl/input/FileFormats.cv.yamltsv"
                    ]
                }, 
                {
                    "doc": "Optional input file, md5,seek,length", 
                    "inputBinding": {
                        "prefix": "--md5_index"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#sims_abundance.tool.cwl/md5index"
                }, 
                {
                    "doc": "Output abundance profile", 
                    "inputBinding": {
                        "prefix": "-o"
                    }, 
                    "type": "string", 
                    "id": "#sims_abundance.tool.cwl/outName"
                }, 
                {
                    "doc": "Profile type", 
                    "inputBinding": {
                        "prefix": "-t"
                    }, 
                    "type": "string", 
                    "id": "#sims_abundance.tool.cwl/profileType", 
                    "format": [
                        "#sims_abundance.tool.cwl/profileType/ProfileTypes.cv.yamlmd5", 
                        "#sims_abundance.tool.cwl/profileType/ProfileTypes.cv.yamllca", 
                        "#sims_abundance.tool.cwl/profileType/ProfileTypes.cv.yamlsource"
                    ]
                }, 
                {
                    "default": 18, 
                    "doc": "Number of sources in m5nr, default 18", 
                    "inputBinding": {
                        "prefix": "-s"
                    }, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#sims_abundance.tool.cwl/sourceNum"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "sims_abundance.log", 
            "doc": "create abundance profile from expanded annotated sims files\nmd5:    sims_abundance.py -t md5 -i <input> -o <output> --coverage <coverage> --cluster <cluster> --md5index <md5index>\nlca:    sims_abundance.py -t lca -i <input> -o <output> --coverage <coverage> --cluster <cluster>\nsource: sims_abundance.py -t source -i <input> -o <output> --coverage <coverage> --cluster <cluster>\n", 
            "class": "CommandLineTool", 
            "baseCommand": [
                "sims_abundance.py"
            ], 
            "label": "abundance profile", 
            "stderr": "sims_abundance.error", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#sims_abundance.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#sims_abundance.tool.cwl/info"
                }, 
                {
                    "doc": "Output abundance profile file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "type": "File", 
                    "id": "#sims_abundance.tool.cwl/output"
                }
            ], 
            "$namespaces": {
                "Types": "ProfileTypes.cv.yaml", 
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#sims_abundance.tool.cwl", 
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
                    "doc": "BerkelyDB of condensed M5NR", 
                    "inputBinding": {
                        "prefix": "--ann_file"
                    }, 
                    "type": "File", 
                    "id": "#sims_annotate.tool.cwl/database"
                }, 
                {
                    "default": 5000, 
                    "doc": "Number of fragment chunks to load in memory at once before processing, default 5000", 
                    "inputBinding": {
                        "prefix": "--frag_num"
                    }, 
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "id": "#sims_annotate.tool.cwl/fragNum"
                }, 
                {
                    "doc": "Input similarity blast-m8 file", 
                    "inputBinding": {
                        "prefix": "--in_sim"
                    }, 
                    "type": "File", 
                    "id": "#sims_annotate.tool.cwl/input", 
                    "format": [
                        "#sims_annotate.tool.cwl/input/FileFormats.cv.yamltsv"
                    ]
                }, 
                {
                    "doc": "Output expanded protein sim file (protein mode only)", 
                    "inputBinding": {
                        "prefix": "--out_expand"
                    }, 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#sims_annotate.tool.cwl/outExpandName"
                }, 
                {
                    "doc": "Output filtered sim file", 
                    "inputBinding": {
                        "prefix": "--out_filter"
                    }, 
                    "type": "string", 
                    "id": "#sims_annotate.tool.cwl/outFilterName"
                }, 
                {
                    "doc": "Output expanded LCA file (protein and rna mode)", 
                    "inputBinding": {
                        "prefix": "--out_lca"
                    }, 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#sims_annotate.tool.cwl/outLcaName"
                }, 
                {
                    "doc": "Output expanded ontology sim file (protein mode only)", 
                    "inputBinding": {
                        "prefix": "--out_ontology"
                    }, 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#sims_annotate.tool.cwl/outOntologyName"
                }, 
                {
                    "doc": "Output expanded rna sim file (rna mode only)", 
                    "inputBinding": {
                        "prefix": "--out_rna"
                    }, 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#sims_annotate.tool.cwl/outRnaName"
                }, 
                {
                    "doc": "Verbose logging mode", 
                    "inputBinding": {
                        "prefix": "--verbose"
                    }, 
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "id": "#sims_annotate.tool.cwl/verbose"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "sims_annotate.log", 
            "doc": "create expanded annotated sims files from input md5 sim file and m5nr db\nprot mode: sims_annotate.pl --verbose --in_sim <input> --ann_file <database> --out_filter <outFilter> --out_expand <outExpand> --out_ontology <outOntology> -out_lca <outLca> --frag_num 5000\nrna mode:  sims_annotate.pl --verbose --in_sim <input> --ann_file <database> --out_filter <outFilter> --out_rna <outRna> --out_lca <outLca> --frag_num 5000\n", 
            "class": "CommandLineTool", 
            "baseCommand": [
                "sims_annotate.pl"
            ], 
            "label": "annotate sims", 
            "stderr": "sims_annotate.error", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#sims_annotate.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#sims_annotate.tool.cwl/info"
                }, 
                {
                    "doc": "Output expanded protein sim file (protein mode only)", 
                    "outputBinding": {
                        "glob": "$(inputs.outExpandName)"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#sims_annotate.tool.cwl/outExpand"
                }, 
                {
                    "doc": "Output filtered similarity file", 
                    "outputBinding": {
                        "glob": "$(inputs.outFilterName)"
                    }, 
                    "type": "File", 
                    "id": "#sims_annotate.tool.cwl/outFilter"
                }, 
                {
                    "doc": "Output expanded LCA file (protein and rna mode)", 
                    "outputBinding": {
                        "glob": "$(inputs.outLcaName)"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#sims_annotate.tool.cwl/outLca"
                }, 
                {
                    "doc": "Output expanded ontology sim file (protein mode only)", 
                    "outputBinding": {
                        "glob": "$(inputs.outOntologyName)"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#sims_annotate.tool.cwl/outOntology"
                }, 
                {
                    "doc": "Output expanded rna sim file (rna mode only)", 
                    "outputBinding": {
                        "glob": "$(inputs.outRnaName)"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#sims_annotate.tool.cwl/outRna"
                }
            ], 
            "$namespaces": {
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#sims_annotate.tool.cwl", 
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
                    "doc": "-t, --field-separator=SEP\nuse SEP instead of non-blank to blank transition\n", 
                    "inputBinding": {
                        "prefix": "-t", 
                        "valueFrom": "$(\"\\u0009\")"
                    }, 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#sort.tool.cwl/field"
                }, 
                {
                    "doc": "File to sort", 
                    "inputBinding": {
                        "position": 1
                    }, 
                    "type": "File", 
                    "id": "#sort.tool.cwl/input", 
                    "format": [
                        "#sort.tool.cwl/input/FileFormats.cv.yamltsv"
                    ]
                }, 
                {
                    "doc": "-k, --key=POS1[,POS2]\nstart a key at POS1, end it at POS2 (origin 1)\n", 
                    "inputBinding": {
                        "prefix": "-k"
                    }, 
                    "type": "string", 
                    "id": "#sort.tool.cwl/key"
                }, 
                {
                    "doc": "-o, --output=FILE\nwrite result to FILE instead of standard output\n", 
                    "inputBinding": {
                        "prefix": "-o"
                    }, 
                    "type": "string", 
                    "id": "#sort.tool.cwl/outName"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "sort.log", 
            "doc": "sort text file base on given field(s)", 
            "class": "CommandLineTool", 
            "baseCommand": [
                "sort"
            ], 
            "label": "GNU sort", 
            "arguments": [
                {
                    "prefix": "-T", 
                    "valueFrom": "$(runtime.tmpdir)"
                }, 
                {
                    "prefix": "-S", 
                    "valueFrom": "$(runtime.ram)M"
                }
            ], 
            "stderr": "sort.error", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#sort.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#sort.tool.cwl/info"
                }, 
                {
                    "doc": "The sorted file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#sort.tool.cwl/output"
                }
            ], 
            "$namespaces": {
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#sort.tool.cwl", 
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
                    "default": 0.1, 
                    "doc": "E-value threshold, default 0.1", 
                    "inputBinding": {
                        "prefix": "-e"
                    }, 
                    "type": [
                        "null", 
                        "float"
                    ], 
                    "id": "#sortmerna.tool.cwl/evalue"
                }, 
                {
                    "default": "./", 
                    "doc": "Directory containing index files with prefix INDEXNAME", 
                    "type": [
                        "null", 
                        "Directory"
                    ], 
                    "id": "#sortmerna.tool.cwl/indexDir"
                }, 
                {
                    "doc": "Prefix for index files", 
                    "type": "string", 
                    "id": "#sortmerna.tool.cwl/indexName"
                }, 
                {
                    "doc": "Input file, sequence (fasta/fastq)", 
                    "inputBinding": {
                        "prefix": "--reads"
                    }, 
                    "type": "File", 
                    "id": "#sortmerna.tool.cwl/input", 
                    "format": [
                        "#sortmerna.tool.cwl/input/FileFormats.cv.yamlfasta", 
                        "#sortmerna.tool.cwl/input/FileFormats.cv.yamlfastq"
                    ]
                }, 
                {
                    "doc": "Reference .fasta file", 
                    "type": "File", 
                    "id": "#sortmerna.tool.cwl/refFasta"
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "sortmerna.log", 
            "doc": "align rRNA fasta file against clustered rRNA index\noutput in blast m8 format\n>sortmerna -a <# core> -m <MB ram> -e 0.1 --blast '1 cigar qcov qstrand' --ref '<refFasta>,<indexDir>/<indexName>' --reads <input> --aligned <input basename>\n", 
            "class": "CommandLineTool", 
            "baseCommand": [
                "sortmerna"
            ], 
            "label": "sortmerna", 
            "arguments": [
                {
                    "prefix": "--blast", 
                    "valueFrom": "1 cigar qcov qstrand"
                }, 
                {
                    "prefix": "-a", 
                    "valueFrom": "$(runtime.cores)"
                }, 
                {
                    "prefix": "--ref", 
                    "valueFrom": "$(inputs.refFasta.path),$(inputs.indexDir.path)/$(inputs.indexName)"
                }, 
                {
                    "prefix": "--aligned", 
                    "valueFrom": "$(inputs.input.basename)"
                }
            ], 
            "stderr": "sortmerna.error", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#sortmerna.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#sortmerna.tool.cwl/info"
                }, 
                {
                    "doc": "Output tab separated aligned file", 
                    "outputBinding": {
                        "glob": "$(inputs.input.basename).blast"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#sortmerna.tool.cwl/output"
                }
            ], 
            "$namespaces": {
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#sortmerna.tool.cwl", 
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
                    "type": "string", 
                    "id": "#preprocess-fastq.workflow.cwl/jobid"
                }, 
                {
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
                    "id": "#preprocess-fastq.workflow.cwl/sequences"
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
            "doc": "Remove and trim low quality reads from fastq files. \nReturn fasta files with reads passed this qc steo and reads removed.\n", 
            "class": "Workflow", 
            "label": "preprocess-fastq", 
            "steps": [
                {
                    "out": [
                        "#preprocess-fastq.workflow.cwl/filter/trimmed", 
                        "#preprocess-fastq.workflow.cwl/filter/rejected"
                    ], 
                    "run": "#DynamicTrimmer.tool.cwl", 
                    "id": "#preprocess-fastq.workflow.cwl/filter", 
                    "in": [
                        {
                            "source": "#preprocess-fastq.workflow.cwl/jobid", 
                            "valueFrom": "$(self).100.preprocess.length.stats", 
                            "id": "#preprocess-fastq.workflow.cwl/filter/output"
                        }, 
                        {
                            "source": "#preprocess-fastq.workflow.cwl/sequences", 
                            "id": "#preprocess-fastq.workflow.cwl/filter/sequences"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#preprocess-fastq.workflow.cwl/rejected2fasta/file"
                    ], 
                    "run": "#seqUtil.tool.cwl", 
                    "id": "#preprocess-fastq.workflow.cwl/rejected2fasta", 
                    "in": [
                        {
                            "default": true, 
                            "id": "#preprocess-fastq.workflow.cwl/rejected2fasta/fastq2fasta"
                        }, 
                        {
                            "source": "#preprocess-fastq.workflow.cwl/jobid", 
                            "valueFrom": "$(self).100.preprocess.removed.fasta", 
                            "id": "#preprocess-fastq.workflow.cwl/rejected2fasta/output"
                        }, 
                        {
                            "source": "#preprocess-fastq.workflow.cwl/filter/rejected", 
                            "id": "#preprocess-fastq.workflow.cwl/rejected2fasta/sequences"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#preprocess-fastq.workflow.cwl/trimmed2fasta/file"
                    ], 
                    "run": "#seqUtil.tool.cwl", 
                    "id": "#preprocess-fastq.workflow.cwl/trimmed2fasta", 
                    "in": [
                        {
                            "default": true, 
                            "id": "#preprocess-fastq.workflow.cwl/trimmed2fasta/fastq2fasta"
                        }, 
                        {
                            "source": "#preprocess-fastq.workflow.cwl/jobid", 
                            "valueFrom": "$(self).100.preprocess.passed.fasta", 
                            "id": "#preprocess-fastq.workflow.cwl/trimmed2fasta/output"
                        }, 
                        {
                            "source": "#preprocess-fastq.workflow.cwl/filter/trimmed", 
                            "valueFrom": "${\n  inputs.sequences.format = \"fastq\" ; return inputs.sequences\n}\n", 
                            "id": "#preprocess-fastq.workflow.cwl/trimmed2fasta/sequences"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputSource": "#preprocess-fastq.workflow.cwl/rejected2fasta/file", 
                    "type": "File", 
                    "id": "#preprocess-fastq.workflow.cwl/rejected"
                }, 
                {
                    "outputSource": "#preprocess-fastq.workflow.cwl/trimmed2fasta/file", 
                    "type": "File", 
                    "id": "#preprocess-fastq.workflow.cwl/trimmed"
                }
            ], 
            "id": "#preprocess-fastq.workflow.cwl"
        }, 
        {
            "inputs": [
                {
                    "type": "File", 
                    "id": "#rna-abundance.workflow.cwl/coverageStats"
                }, 
                {
                    "type": "string", 
                    "id": "#rna-abundance.workflow.cwl/jobid"
                }, 
                {
                    "type": "File", 
                    "id": "#rna-abundance.workflow.cwl/rnaClustMap"
                }, 
                {
                    "type": "File", 
                    "id": "#rna-abundance.workflow.cwl/rnaExpand"
                }, 
                {
                    "type": "File", 
                    "id": "#rna-abundance.workflow.cwl/rnaLCA"
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
            "doc": "RNAs - abundace profiles from annotated files", 
            "class": "Workflow", 
            "label": "rna abundance", 
            "steps": [
                {
                    "out": [
                        "#rna-abundance.workflow.cwl/lcaProfile/output"
                    ], 
                    "run": "#sims_abundance.tool.cwl", 
                    "id": "#rna-abundance.workflow.cwl/lcaProfile", 
                    "in": [
                        {
                            "source": "#rna-abundance.workflow.cwl/rnaClustMap", 
                            "id": "#rna-abundance.workflow.cwl/lcaProfile/cluster"
                        }, 
                        {
                            "source": "#rna-abundance.workflow.cwl/coverageStats", 
                            "id": "#rna-abundance.workflow.cwl/lcaProfile/coverage"
                        }, 
                        {
                            "source": "#rna-abundance.workflow.cwl/rnaLCA", 
                            "id": "#rna-abundance.workflow.cwl/lcaProfile/input"
                        }, 
                        {
                            "source": "#rna-abundance.workflow.cwl/jobid", 
                            "valueFrom": "$(self).700.annotation.lca.abundance", 
                            "id": "#rna-abundance.workflow.cwl/lcaProfile/outName"
                        }, 
                        {
                            "default": "lca", 
                            "id": "#rna-abundance.workflow.cwl/lcaProfile/profileType"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#rna-abundance.workflow.cwl/md5Profile/output"
                    ], 
                    "run": "#sims_abundance.tool.cwl", 
                    "id": "#rna-abundance.workflow.cwl/md5Profile", 
                    "in": [
                        {
                            "source": "#rna-abundance.workflow.cwl/rnaClustMap", 
                            "id": "#rna-abundance.workflow.cwl/md5Profile/cluster"
                        }, 
                        {
                            "source": "#rna-abundance.workflow.cwl/coverageStats", 
                            "id": "#rna-abundance.workflow.cwl/md5Profile/coverage"
                        }, 
                        {
                            "source": "#rna-abundance.workflow.cwl/rnaExpand", 
                            "id": "#rna-abundance.workflow.cwl/md5Profile/input"
                        }, 
                        {
                            "source": "#rna-abundance.workflow.cwl/jobid", 
                            "valueFrom": "$(self).700.annotation.md5.abundance", 
                            "id": "#rna-abundance.workflow.cwl/md5Profile/outName"
                        }, 
                        {
                            "default": "md5", 
                            "id": "#rna-abundance.workflow.cwl/md5Profile/profileType"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#rna-abundance.workflow.cwl/sourceStats/output"
                    ], 
                    "run": "#sims_abundance.tool.cwl", 
                    "id": "#rna-abundance.workflow.cwl/sourceStats", 
                    "in": [
                        {
                            "source": "#rna-abundance.workflow.cwl/rnaClustMap", 
                            "id": "#rna-abundance.workflow.cwl/sourceStats/cluster"
                        }, 
                        {
                            "source": "#rna-abundance.workflow.cwl/coverageStats", 
                            "id": "#rna-abundance.workflow.cwl/sourceStats/coverage"
                        }, 
                        {
                            "source": "#rna-abundance.workflow.cwl/rnaExpand", 
                            "id": "#rna-abundance.workflow.cwl/sourceStats/input"
                        }, 
                        {
                            "source": "#rna-abundance.workflow.cwl/jobid", 
                            "valueFrom": "$(self).700.annotation.source.stats", 
                            "id": "#rna-abundance.workflow.cwl/sourceStats/outName"
                        }, 
                        {
                            "default": "source", 
                            "id": "#rna-abundance.workflow.cwl/sourceStats/profileType"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputSource": "#rna-abundance.workflow.cwl/lcaProfile/output", 
                    "type": "File", 
                    "id": "#rna-abundance.workflow.cwl/lcaProfileOut"
                }, 
                {
                    "outputSource": "#rna-abundance.workflow.cwl/md5Profile/output", 
                    "type": "File", 
                    "id": "#rna-abundance.workflow.cwl/md5ProfileOut"
                }, 
                {
                    "outputSource": "#rna-abundance.workflow.cwl/sourceStats/output", 
                    "type": "File", 
                    "id": "#rna-abundance.workflow.cwl/sourceStatsOut"
                }
            ], 
            "id": "#rna-abundance.workflow.cwl"
        }, 
        {
            "inputs": [
                {
                    "type": "string", 
                    "id": "#rna-annotation.workflow.cwl/jobid"
                }, 
                {
                    "type": "File", 
                    "id": "#rna-annotation.workflow.cwl/m5rnaBDB"
                }, 
                {
                    "type": "File", 
                    "id": "#rna-annotation.workflow.cwl/m5rnaClust"
                }, 
                {
                    "type": "File", 
                    "id": "#rna-annotation.workflow.cwl/m5rnaFull"
                }, 
                {
                    "type": "Directory", 
                    "id": "#rna-annotation.workflow.cwl/m5rnaIndex"
                }, 
                {
                    "type": "string", 
                    "id": "#rna-annotation.workflow.cwl/m5rnaPrefix"
                }, 
                {
                    "type": "File", 
                    "id": "#rna-annotation.workflow.cwl/sequences"
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
            "doc": "RNAs - predict, cluster, identify, annotate", 
            "class": "Workflow", 
            "label": "rna annotation", 
            "steps": [
                {
                    "out": [
                        "#rna-annotation.workflow.cwl/annotateSims/outFilter", 
                        "#rna-annotation.workflow.cwl/annotateSims/outRna", 
                        "#rna-annotation.workflow.cwl/annotateSims/outLca"
                    ], 
                    "run": "#sims_annotate.tool.cwl", 
                    "id": "#rna-annotation.workflow.cwl/annotateSims", 
                    "in": [
                        {
                            "source": "#rna-annotation.workflow.cwl/m5rnaBDB", 
                            "id": "#rna-annotation.workflow.cwl/annotateSims/database"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/bleachSims/output", 
                            "id": "#rna-annotation.workflow.cwl/annotateSims/input"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/jobid", 
                            "valueFrom": "$(self).450.rna.sims.filter", 
                            "id": "#rna-annotation.workflow.cwl/annotateSims/outFilterName"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/jobid", 
                            "valueFrom": "$(self).450.rna.expand.lca", 
                            "id": "#rna-annotation.workflow.cwl/annotateSims/outLcaName"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/jobid", 
                            "valueFrom": "$(self).450.rna.expand.rna", 
                            "id": "#rna-annotation.workflow.cwl/annotateSims/outRnaName"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#rna-annotation.workflow.cwl/bleachSims/output"
                    ], 
                    "run": "#bleachsims.tool.cwl", 
                    "id": "#rna-annotation.workflow.cwl/bleachSims", 
                    "in": [
                        {
                            "source": "#rna-annotation.workflow.cwl/rnaBlat/output", 
                            "id": "#rna-annotation.workflow.cwl/bleachSims/input"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/jobid", 
                            "valueFrom": "$(self).450.rna.sims", 
                            "id": "#rna-annotation.workflow.cwl/bleachSims/outName"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#rna-annotation.workflow.cwl/formatCluster/output"
                    ], 
                    "run": "#format_cluster.tool.cwl", 
                    "id": "#rna-annotation.workflow.cwl/formatCluster", 
                    "in": [
                        {
                            "source": "#rna-annotation.workflow.cwl/rnaCluster/outClstr", 
                            "id": "#rna-annotation.workflow.cwl/formatCluster/input"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/jobid", 
                            "valueFrom": "$(self).440.cluster.rna.97.mapping", 
                            "id": "#rna-annotation.workflow.cwl/formatCluster/outName"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#rna-annotation.workflow.cwl/rnaBlat/output"
                    ], 
                    "run": "#blat.tool.cwl", 
                    "id": "#rna-annotation.workflow.cwl/rnaBlat", 
                    "in": [
                        {
                            "source": "#rna-annotation.workflow.cwl/m5rnaFull", 
                            "id": "#rna-annotation.workflow.cwl/rnaBlat/database"
                        }, 
                        {
                            "default": "dna", 
                            "id": "#rna-annotation.workflow.cwl/rnaBlat/dbType"
                        }, 
                        {
                            "default": true, 
                            "id": "#rna-annotation.workflow.cwl/rnaBlat/fastMap"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/jobid", 
                            "valueFrom": "$(self).450.rna.sims.full", 
                            "id": "#rna-annotation.workflow.cwl/rnaBlat/outName"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/rnaCluster/outSeq", 
                            "id": "#rna-annotation.workflow.cwl/rnaBlat/query"
                        }, 
                        {
                            "default": "rna", 
                            "id": "#rna-annotation.workflow.cwl/rnaBlat/queryType"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#rna-annotation.workflow.cwl/rnaCluster/outSeq", 
                        "#rna-annotation.workflow.cwl/rnaCluster/outClstr"
                    ], 
                    "run": "#cdhit-est.tool.cwl", 
                    "id": "#rna-annotation.workflow.cwl/rnaCluster", 
                    "in": [
                        {
                            "default": 0.97, 
                            "id": "#rna-annotation.workflow.cwl/rnaCluster/identity"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/rnaFeature/output", 
                            "id": "#rna-annotation.workflow.cwl/rnaCluster/input"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/jobid", 
                            "valueFrom": "$(self).440.cluster.rna.97.fna", 
                            "id": "#rna-annotation.workflow.cwl/rnaCluster/outName"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#rna-annotation.workflow.cwl/rnaFeature/output"
                    ], 
                    "run": "#rna_feature.tool.cwl", 
                    "id": "#rna-annotation.workflow.cwl/rnaFeature", 
                    "in": [
                        {
                            "source": "#rna-annotation.workflow.cwl/sorttab/output", 
                            "id": "#rna-annotation.workflow.cwl/rnaFeature/aligned"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/jobid", 
                            "valueFrom": "$(self).425.search.rna.fna", 
                            "id": "#rna-annotation.workflow.cwl/rnaFeature/outName"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/sortseq/file", 
                            "id": "#rna-annotation.workflow.cwl/rnaFeature/sequence"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#rna-annotation.workflow.cwl/sortmerna/output"
                    ], 
                    "run": "#sortmerna.tool.cwl", 
                    "id": "#rna-annotation.workflow.cwl/sortmerna", 
                    "in": [
                        {
                            "source": "#rna-annotation.workflow.cwl/m5rnaIndex", 
                            "id": "#rna-annotation.workflow.cwl/sortmerna/indexDir"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/m5rnaPrefix", 
                            "id": "#rna-annotation.workflow.cwl/sortmerna/indexName"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/sequences", 
                            "id": "#rna-annotation.workflow.cwl/sortmerna/input"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/m5rnaClust", 
                            "id": "#rna-annotation.workflow.cwl/sortmerna/refFasta"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#rna-annotation.workflow.cwl/sortseq/file"
                    ], 
                    "run": "#seqUtil.tool.cwl", 
                    "id": "#rna-annotation.workflow.cwl/sortseq", 
                    "in": [
                        {
                            "source": "#rna-annotation.workflow.cwl/sequences", 
                            "valueFrom": "$(self.basename).sort.tab", 
                            "id": "#rna-annotation.workflow.cwl/sortseq/output"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/sequences", 
                            "id": "#rna-annotation.workflow.cwl/sortseq/sequences"
                        }, 
                        {
                            "default": true, 
                            "id": "#rna-annotation.workflow.cwl/sortseq/sortbyid2tab"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#rna-annotation.workflow.cwl/sorttab/output"
                    ], 
                    "run": "#sort.tool.cwl", 
                    "id": "#rna-annotation.workflow.cwl/sorttab", 
                    "in": [
                        {
                            "source": "#rna-annotation.workflow.cwl/sortmerna/output", 
                            "id": "#rna-annotation.workflow.cwl/sorttab/input"
                        }, 
                        {
                            "default": "1,1", 
                            "id": "#rna-annotation.workflow.cwl/sorttab/key"
                        }, 
                        {
                            "source": "#rna-annotation.workflow.cwl/sortmerna/output", 
                            "valueFrom": "$(self.basename).sort", 
                            "id": "#rna-annotation.workflow.cwl/sorttab/outName"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputSource": "#rna-annotation.workflow.cwl/formatCluster/output", 
                    "type": "File", 
                    "id": "#rna-annotation.workflow.cwl/rnaClustMapOut"
                }, 
                {
                    "outputSource": "#rna-annotation.workflow.cwl/rnaCluster/outSeq", 
                    "type": "File", 
                    "id": "#rna-annotation.workflow.cwl/rnaClustSeqOut"
                }, 
                {
                    "outputSource": "#rna-annotation.workflow.cwl/annotateSims/outRna", 
                    "type": "File", 
                    "id": "#rna-annotation.workflow.cwl/rnaExpandOut"
                }, 
                {
                    "outputSource": "#rna-annotation.workflow.cwl/rnaFeature/output", 
                    "type": "File", 
                    "id": "#rna-annotation.workflow.cwl/rnaFeatureOut"
                }, 
                {
                    "outputSource": "#rna-annotation.workflow.cwl/annotateSims/outFilter", 
                    "type": "File", 
                    "id": "#rna-annotation.workflow.cwl/rnaFilterOut"
                }, 
                {
                    "outputSource": "#rna-annotation.workflow.cwl/annotateSims/outLca", 
                    "type": "File", 
                    "id": "#rna-annotation.workflow.cwl/rnaLCAOut"
                }, 
                {
                    "outputSource": "#rna-annotation.workflow.cwl/bleachSims/output", 
                    "type": "File", 
                    "id": "#rna-annotation.workflow.cwl/rnaSimsOut"
                }
            ], 
            "id": "#rna-annotation.workflow.cwl"
        }, 
        {
            "inputs": [
                {
                    "type": "File", 
                    "id": "#main/coverageStats"
                }, 
                {
                    "type": "string", 
                    "id": "#main/jobid"
                }, 
                {
                    "type": "File", 
                    "id": "#main/m5rnaBDB"
                }, 
                {
                    "type": "File", 
                    "id": "#main/m5rnaClust"
                }, 
                {
                    "type": "File", 
                    "id": "#main/m5rnaFull"
                }, 
                {
                    "type": "Directory", 
                    "id": "#main/m5rnaIndex"
                }, 
                {
                    "type": "string", 
                    "id": "#main/m5rnaPrefix"
                }, 
                {
                    "type": {
                        "items": "File", 
                        "type": "array"
                    }, 
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
                }, 
                {
                    "class": "SubworkflowFeatureRequirement"
                }
            ], 
            "doc": "RNAs - preprocess, annotation, abundance", 
            "class": "Workflow", 
            "label": "rna full analysis", 
            "steps": [
                {
                    "out": [
                        "#main/preProcess/trimmed", 
                        "#main/preProcess/rejected"
                    ], 
                    "run": "#preprocess-fastq.workflow.cwl", 
                    "id": "#main/preProcess", 
                    "in": [
                        {
                            "source": "#main/jobid", 
                            "id": "#main/preProcess/jobid"
                        }, 
                        {
                            "source": "#main/sequences", 
                            "id": "#main/preProcess/sequences"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/rnaAbundance/md5ProfileOut", 
                        "#main/rnaAbundance/lcaProfileOut", 
                        "#main/rnaAbundance/sourceStatsOut"
                    ], 
                    "run": "#rna-abundance.workflow.cwl", 
                    "id": "#main/rnaAbundance", 
                    "in": [
                        {
                            "source": "#main/coverageStats", 
                            "id": "#main/rnaAbundance/coverageStats"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "id": "#main/rnaAbundance/jobid"
                        }, 
                        {
                            "source": "#main/rnaAnnotate/rnaClustMapOut", 
                            "id": "#main/rnaAbundance/rnaClustMap"
                        }, 
                        {
                            "source": "#main/rnaAnnotate/rnaExpandOut", 
                            "id": "#main/rnaAbundance/rnaExpand"
                        }, 
                        {
                            "source": "#main/rnaAnnotate/rnaLCAOut", 
                            "id": "#main/rnaAbundance/rnaLCA"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/rnaAnnotate/rnaFeatureOut", 
                        "#main/rnaAnnotate/rnaClustSeqOut", 
                        "#main/rnaAnnotate/rnaClustMapOut", 
                        "#main/rnaAnnotate/rnaSimsOut", 
                        "#main/rnaAnnotate/rnaFilterOut", 
                        "#main/rnaAnnotate/rnaExpandOut", 
                        "#main/rnaAnnotate/rnaLCAOut"
                    ], 
                    "run": "#rna-annotation.workflow.cwl", 
                    "id": "#main/rnaAnnotate", 
                    "in": [
                        {
                            "source": "#main/jobid", 
                            "id": "#main/rnaAnnotate/jobid"
                        }, 
                        {
                            "source": "#main/m5rnaBDB", 
                            "id": "#main/rnaAnnotate/m5rnaBDB"
                        }, 
                        {
                            "source": "#main/m5rnaClust", 
                            "id": "#main/rnaAnnotate/m5rnaClust"
                        }, 
                        {
                            "source": "#main/m5rnaFull", 
                            "id": "#main/rnaAnnotate/m5rnaFull"
                        }, 
                        {
                            "source": "#main/m5rnaIndex", 
                            "id": "#main/rnaAnnotate/m5rnaIndex"
                        }, 
                        {
                            "source": "#main/m5rnaPrefix", 
                            "id": "#main/rnaAnnotate/m5rnaPrefix"
                        }, 
                        {
                            "source": "#main/preProcess/trimmed", 
                            "id": "#main/rnaAnnotate/sequences"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputSource": "#main/rnaAbundance/lcaProfileOut", 
                    "type": "File", 
                    "id": "#main/lcaProfileOut"
                }, 
                {
                    "outputSource": "#main/rnaAbundance/md5ProfileOut", 
                    "type": "File", 
                    "id": "#main/md5ProfileOut"
                }, 
                {
                    "outputSource": "#main/preProcess/rejected", 
                    "type": "File", 
                    "id": "#main/preProcessRejected"
                }, 
                {
                    "outputSource": "#main/preProcess/trimmed", 
                    "type": "File", 
                    "id": "#main/preProcessTrimmed"
                }, 
                {
                    "outputSource": "#main/rnaAnnotate/rnaClustMapOut", 
                    "type": "File", 
                    "id": "#main/rnaClustMapOut"
                }, 
                {
                    "outputSource": "#main/rnaAnnotate/rnaClustSeqOut", 
                    "type": "File", 
                    "id": "#main/rnaClustSeqOut"
                }, 
                {
                    "outputSource": "#main/rnaAnnotate/rnaFeatureOut", 
                    "type": "File", 
                    "id": "#main/rnaFeatureOut"
                }, 
                {
                    "outputSource": "#main/rnaAnnotate/rnaFilterOut", 
                    "type": "File", 
                    "id": "#main/rnaFilterOut"
                }, 
                {
                    "outputSource": "#main/rnaAnnotate/rnaSimsOut", 
                    "type": "File", 
                    "id": "#main/rnaSimsOut"
                }, 
                {
                    "outputSource": "#main/rnaAbundance/sourceStatsOut", 
                    "type": "File", 
                    "id": "#main/sourceStatsOut"
                }
            ], 
            "id": "#main"
        }
    ]
}