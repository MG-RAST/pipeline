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
                    "listing": "$(inputs.sequences)", 
                    "class": "InitialWorkDirRequirement"
                }, 
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "DynamicTrimmer.log", 
            "stderr": "DynamicTrimmer.error", 
            "inputs": [
                {
                    "inputBinding": {
                        "position": 1
                    }, 
                    "type": {
                        "type": "array", 
                        "items": "File", 
                        "inputBinding": {
                            "valueFrom": "$(self.basename)"
                        }
                    }, 
                    "id": "#DynamicTrimmer.tool.cwl/sequences"
                }
            ], 
            "baseCommand": [
                "DynamicTrimmer.pl"
            ], 
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
                    "type": [
                        "File"
                    ], 
                    "format": "file:///Users/wolfganggerlach/awe_data/pipeline/CWL/Tools/fastq", 
                    "outputBinding": {
                        "glob": "*.rejected.fastq"
                    }, 
                    "id": "#DynamicTrimmer.tool.cwl/rejected"
                }, 
                {
                    "type": [
                        "File"
                    ], 
                    "format": "file:///Users/wolfganggerlach/awe_data/pipeline/CWL/Tools/fastq", 
                    "outputBinding": {
                        "glob": "*.trimmed.fastq"
                    }, 
                    "id": "#DynamicTrimmer.tool.cwl/trimmed"
                }
            ], 
            "id": "#DynamicTrimmer.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "label": "BLAT", 
            "doc": "fast sequence search command line tool\n>blat -fastMap -t dna -q rna -out blast8 <database> <query> <output>\n", 
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
            "stdout": "blat.log", 
            "stderr": "blat.error", 
            "inputs": [
                {
                    "type": "File", 
                    "doc": "Database fasta format file", 
                    "format": [
                        "#blat.tool.cwl/database/FileFormats.cv.yamlfasta"
                    ], 
                    "inputBinding": {
                        "position": 1
                    }, 
                    "id": "#blat.tool.cwl/database"
                }, 
                {
                    "type": "string", 
                    "doc": "Database type", 
                    "format": [
                        "#blat.tool.cwl/dbType/BlatTypes.cv.yamldna", 
                        "#blat.tool.cwl/dbType/BlatTypes.cv.yamlprot", 
                        "#blat.tool.cwl/dbType/BlatTypes.cv.yamldnax"
                    ], 
                    "inputBinding": {
                        "prefix": "-t=", 
                        "separate": false
                    }, 
                    "id": "#blat.tool.cwl/dbType"
                }, 
                {
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "doc": "Run for fast DNA/DNA remapping - not allowing introns", 
                    "inputBinding": {
                        "prefix": "-fastMap"
                    }, 
                    "id": "#blat.tool.cwl/fastMap"
                }, 
                {
                    "type": "string", 
                    "doc": "Output name", 
                    "inputBinding": {
                        "position": 3
                    }, 
                    "id": "#blat.tool.cwl/outName"
                }, 
                {
                    "type": "File", 
                    "doc": "Query fasta format file", 
                    "format": [
                        "#blat.tool.cwl/query/FileFormats.cv.yamlfasta"
                    ], 
                    "inputBinding": {
                        "position": 2
                    }, 
                    "id": "#blat.tool.cwl/query"
                }, 
                {
                    "type": "string", 
                    "doc": "Query type", 
                    "format": [
                        "#blat.tool.cwl/queryType/BlatTypes.cv.yamldna", 
                        "#blat.tool.cwl/queryType/BlatTypes.cv.yamlrna", 
                        "#blat.tool.cwl/queryType/BlatTypes.cv.yamlprot", 
                        "#blat.tool.cwl/queryType/BlatTypes.cv.yamldnax", 
                        "#blat.tool.cwl/queryType/BlatTypes.cv.yamlrnax"
                    ], 
                    "inputBinding": {
                        "prefix": "-q=", 
                        "separate": false
                    }, 
                    "id": "#blat.tool.cwl/queryType"
                }
            ], 
            "baseCommand": [
                "blat"
            ], 
            "arguments": [
                "-out=blast8"
            ], 
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
                    "type": "File", 
                    "doc": "Output tab separated similarity file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "id": "#blat.tool.cwl/output"
                }
            ], 
            "id": "#blat.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "label": "bleachsims", 
            "doc": "filter similarity file by E-value and number of hits\n>bleachsims -s <input> -o <output> -m 20 -r 0 -c 3\n", 
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
            "stdout": "bleachsims.log", 
            "stderr": "bleachsims.error", 
            "inputs": [
                {
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "doc": "Remove all evalues with an exponent lower than cutoff, default 3", 
                    "default": 3, 
                    "inputBinding": {
                        "prefix": "-c"
                    }, 
                    "id": "#bleachsims.tool.cwl/cutoff"
                }, 
                {
                    "type": "File", 
                    "doc": "Input similarity blast-m8 file", 
                    "format": [
                        "#bleachsims.tool.cwl/input/FileFormats.cv.yamltsv"
                    ], 
                    "inputBinding": {
                        "prefix": "-s"
                    }, 
                    "id": "#bleachsims.tool.cwl/input"
                }, 
                {
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "doc": "Minimum", 
                    "default": 20, 
                    "inputBinding": {
                        "prefix": "-m"
                    }, 
                    "id": "#bleachsims.tool.cwl/min"
                }, 
                {
                    "type": "string", 
                    "doc": "Output name", 
                    "inputBinding": {
                        "prefix": "-o"
                    }, 
                    "id": "#bleachsims.tool.cwl/outName"
                }, 
                {
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "doc": "Best evalue plus this exponent that will be returned, default 0 (no range)", 
                    "default": 0, 
                    "inputBinding": {
                        "prefix": "-r"
                    }, 
                    "id": "#bleachsims.tool.cwl/range"
                }
            ], 
            "baseCommand": [
                "bleachsims"
            ], 
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
                    "type": "File", 
                    "doc": "Output filtered similarity blast-m8 file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "id": "#bleachsims.tool.cwl/output"
                }
            ], 
            "id": "#bleachsims.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "label": "CD-HIT-est", 
            "doc": "cluster nucleotide sequences\nuse max available cpus and memory\n>cdhit-est -n 9 -d 0 -T 0 -M 0 -c 0.97 -i <input> -o <output>\n", 
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
            "stdout": "cdhit-est.log", 
            "stderr": "cdhit-est.error", 
            "inputs": [
                {
                    "type": [
                        "null", 
                        "float"
                    ], 
                    "doc": "Percent identity threshold, default 0.97", 
                    "default": 0.97, 
                    "inputBinding": {
                        "prefix": "-c"
                    }, 
                    "id": "#cdhit-est.tool.cwl/identity"
                }, 
                {
                    "type": "File", 
                    "doc": "Input fasta format file", 
                    "format": [
                        "#cdhit-est.tool.cwl/input/FileFormats.cv.yamlfasta"
                    ], 
                    "inputBinding": {
                        "prefix": "-i"
                    }, 
                    "id": "#cdhit-est.tool.cwl/input"
                }, 
                {
                    "type": "string", 
                    "doc": "Output name", 
                    "inputBinding": {
                        "prefix": "-o"
                    }, 
                    "id": "#cdhit-est.tool.cwl/outName"
                }, 
                {
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "doc": "Word length, default 9", 
                    "default": 9, 
                    "inputBinding": {
                        "prefix": "-n"
                    }, 
                    "id": "#cdhit-est.tool.cwl/word"
                }
            ], 
            "baseCommand": [
                "cdhit-est"
            ], 
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
                    "type": "File", 
                    "doc": "Output cluster mapping file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName).clstr"
                    }, 
                    "id": "#cdhit-est.tool.cwl/outClstr"
                }, 
                {
                    "type": "File", 
                    "doc": "Output fasta format file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "id": "#cdhit-est.tool.cwl/outSeq"
                }
            ], 
            "id": "#cdhit-est.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "label": "cluster file reformat", 
            "doc": "re-formats cd-hit .clstr file into mg-rast .mapping file\n>format_cluster.pl --input <input> --output <output>\n", 
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
            "stdout": "format_cluster.log", 
            "stderr": "format_cluster.error", 
            "inputs": [
                {
                    "type": "File", 
                    "doc": "Input .clstr format file", 
                    "inputBinding": {
                        "prefix": "--input"
                    }, 
                    "id": "#format_cluster.tool.cwl/input"
                }, 
                {
                    "type": "string", 
                    "doc": "Output .mapping format file", 
                    "inputBinding": {
                        "prefix": "--output"
                    }, 
                    "id": "#format_cluster.tool.cwl/outName"
                }
            ], 
            "baseCommand": [
                "format_cluster.pl"
            ], 
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
                    "type": "File", 
                    "doc": "Output .mapping format file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "id": "#format_cluster.tool.cwl/output"
                }
            ], 
            "id": "#format_cluster.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "label": "rna features", 
            "doc": "identify rRNAs features from given rRNA fasta and blast aligned files\n>rna_feature.pl --seq <sequence> --sim <aligned> --ident 75 --output <output>\n", 
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
            "stdout": "rna_feature.log", 
            "stderr": "rna_feature.error", 
            "inputs": [
                {
                    "type": "File", 
                    "doc": "Tab separated similarity file", 
                    "format": [
                        "#rna_feature.tool.cwl/aligned/FileFormats.cv.yamltsv"
                    ], 
                    "inputBinding": {
                        "prefix": "--sim"
                    }, 
                    "id": "#rna_feature.tool.cwl/aligned"
                }, 
                {
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "doc": "Percent identity threshold, default 75", 
                    "default": 75, 
                    "inputBinding": {
                        "prefix": "--ident"
                    }, 
                    "id": "#rna_feature.tool.cwl/identity"
                }, 
                {
                    "type": "string", 
                    "doc": "Output fasta format file", 
                    "inputBinding": {
                        "prefix": "--output"
                    }, 
                    "id": "#rna_feature.tool.cwl/outName"
                }, 
                {
                    "type": "File", 
                    "doc": "Tab separated sequence file", 
                    "format": [
                        "#rna_feature.tool.cwl/sequence/FileFormats.cv.yamltsv"
                    ], 
                    "inputBinding": {
                        "prefix": "--seq"
                    }, 
                    "id": "#rna_feature.tool.cwl/sequence"
                }
            ], 
            "baseCommand": [
                "rna_feature.pl"
            ], 
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
                    "type": "File", 
                    "doc": "Output fasta format file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "id": "#rna_feature.tool.cwl/output"
                }
            ], 
            "id": "#rna_feature.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "label": "seqUtil", 
            "doc": "Convert fastq into fasta and fasta into tab files.", 
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
            "stdout": "seqUtil.log", 
            "stderr": "seqUtil.error", 
            "inputs": [
                {
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "inputBinding": {
                        "prefix": "--bowtie_truncate"
                    }, 
                    "id": "#seqUtil.tool.cwl/bowtie_truncate"
                }, 
                {
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "inputBinding": {
                        "prefix": "--fasta2tab"
                    }, 
                    "id": "#seqUtil.tool.cwl/fasta2tab"
                }, 
                {
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "inputBinding": {
                        "prefix": "--fastq2fasta"
                    }, 
                    "id": "#seqUtil.tool.cwl/fastq2fasta"
                }, 
                {
                    "type": "string", 
                    "inputBinding": {
                        "prefix": "--output"
                    }, 
                    "id": "#seqUtil.tool.cwl/output"
                }, 
                {
                    "type": "File", 
                    "format": [
                        "#seqUtil.tool.cwl/sequences/FileFormats.cv.yamlfastq", 
                        "#seqUtil.tool.cwl/sequences/FileFormats.cv.yamlfasta"
                    ], 
                    "inputBinding": {
                        "prefix": "--input"
                    }, 
                    "id": "#seqUtil.tool.cwl/sequences"
                }, 
                {
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "inputBinding": {
                        "prefix": "--sortbyid2tab"
                    }, 
                    "id": "#seqUtil.tool.cwl/sortbyid2tab"
                }
            ], 
            "baseCommand": [
                "seqUtil"
            ], 
            "arguments": [
                {
                    "prefix": null, 
                    "valueFrom": "${\n   if (  (\"format\" in inputs.sequences) && (inputs.sequences.format.split(\"/\").slice(-1)[0] == \"fastq\")  ) { return \"--fastq\"; } else { return \"\" ; }  \n }\n"
                }
            ], 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#seqUtil.tool.cwl/error"
                }, 
                {
                    "type": "File", 
                    "format": "${\n  if (inputs.fasta2tab) \n      { return \"tsv\" ;}\n  else if (inputs.sortbyid2tab) \n      { return \"tsv\" ;}\n  else if (inputs.fastq2fasta) \n      { return \"fasta\";}\n  else if (inputs.sequences.format) \n      { return inputs.sequences.format ;}\n  else { return '' ;}\n  return \"\" ;\n}\n", 
                    "outputBinding": {
                        "glob": "$(inputs.output)"
                    }, 
                    "id": "#seqUtil.tool.cwl/file"
                }, 
                {
                    "type": "stdout", 
                    "id": "#seqUtil.tool.cwl/info"
                }
            ], 
            "id": "#seqUtil.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "label": "abundance profile", 
            "doc": "create abundance profile from expanded annotated sims files\nmd5:    sims_abundance.py -t md5 -i <input> -o <output> --coverage <coverage> --cluster <cluster> --md5index <md5index>\nlca:    sims_abundance.py -t lca -i <input> -o <output> --coverage <coverage> --cluster <cluster>\nsource: sims_abundance.py -t source -i <input> -o <output> --coverage <coverage> --cluster <cluster>\n", 
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
            "stdout": "sims_abundance.log", 
            "stderr": "sims_abundance.error", 
            "inputs": [
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "doc": "Optional input file, cluster mapping", 
                    "inputBinding": {
                        "prefix": "--cluster"
                    }, 
                    "id": "#sims_abundance.tool.cwl/cluster"
                }, 
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "doc": "Optional input file, assembly coverage", 
                    "inputBinding": {
                        "prefix": "--coverage"
                    }, 
                    "id": "#sims_abundance.tool.cwl/coverage"
                }, 
                {
                    "type": "File", 
                    "doc": "Input expanded sims file", 
                    "format": [
                        "#sims_abundance.tool.cwl/input/FileFormats.cv.yamltsv"
                    ], 
                    "inputBinding": {
                        "prefix": "-i"
                    }, 
                    "id": "#sims_abundance.tool.cwl/input"
                }, 
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "doc": "Optional input file, md5,seek,length", 
                    "inputBinding": {
                        "prefix": "--md5_index"
                    }, 
                    "id": "#sims_abundance.tool.cwl/md5index"
                }, 
                {
                    "type": "string", 
                    "doc": "Output abundance profile", 
                    "inputBinding": {
                        "prefix": "-o"
                    }, 
                    "id": "#sims_abundance.tool.cwl/outName"
                }, 
                {
                    "type": "string", 
                    "doc": "Profile type", 
                    "format": [
                        "#sims_abundance.tool.cwl/profileType/ProfileTypes.cv.yamlmd5", 
                        "#sims_abundance.tool.cwl/profileType/ProfileTypes.cv.yamllca", 
                        "#sims_abundance.tool.cwl/profileType/ProfileTypes.cv.yamlsource"
                    ], 
                    "inputBinding": {
                        "prefix": "-t"
                    }, 
                    "id": "#sims_abundance.tool.cwl/profileType"
                }, 
                {
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "doc": "Number of sources in m5nr, default 18", 
                    "default": 18, 
                    "inputBinding": {
                        "prefix": "-s"
                    }, 
                    "id": "#sims_abundance.tool.cwl/sourceNum"
                }
            ], 
            "baseCommand": [
                "sims_abundance.py"
            ], 
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
                    "type": "File", 
                    "doc": "Output abundance profile file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "id": "#sims_abundance.tool.cwl/output"
                }
            ], 
            "id": "#sims_abundance.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "label": "annotate sims", 
            "doc": "create expanded annotated sims files from input md5 sim file and m5nr db\nprot mode: sims_annotate.pl --verbose --in_sim <input> --ann_file <database> --out_filter <outFilter> --out_expand <outExpand> --out_ontology <outOntology> -out_lca <outLca> --frag_num 5000\nrna mode:  sims_annotate.pl --verbose --in_sim <input> --ann_file <database> --out_filter <outFilter> --out_rna <outRna> --out_lca <outLca> --frag_num 5000\n", 
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
            "stdout": "sims_annotate.log", 
            "stderr": "sims_annotate.error", 
            "inputs": [
                {
                    "type": "File", 
                    "doc": "BerkelyDB of condensed M5NR", 
                    "inputBinding": {
                        "prefix": "--ann_file"
                    }, 
                    "id": "#sims_annotate.tool.cwl/database"
                }, 
                {
                    "type": [
                        "null", 
                        "int"
                    ], 
                    "doc": "Number of fragment chunks to load in memory at once before processing, default 5000", 
                    "default": 5000, 
                    "inputBinding": {
                        "prefix": "--frag_num"
                    }, 
                    "id": "#sims_annotate.tool.cwl/fragNum"
                }, 
                {
                    "type": "File", 
                    "doc": "Input similarity blast-m8 file", 
                    "format": [
                        "#sims_annotate.tool.cwl/input/FileFormats.cv.yamltsv"
                    ], 
                    "inputBinding": {
                        "prefix": "--in_sim"
                    }, 
                    "id": "#sims_annotate.tool.cwl/input"
                }, 
                {
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "doc": "Output expanded protein sim file (protein mode only)", 
                    "inputBinding": {
                        "prefix": "--out_expand"
                    }, 
                    "id": "#sims_annotate.tool.cwl/outExpandName"
                }, 
                {
                    "type": "string", 
                    "doc": "Output filtered sim file", 
                    "inputBinding": {
                        "prefix": "--out_filter"
                    }, 
                    "id": "#sims_annotate.tool.cwl/outFilterName"
                }, 
                {
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "doc": "Output expanded LCA file (protein and rna mode)", 
                    "inputBinding": {
                        "prefix": "--out_lca"
                    }, 
                    "id": "#sims_annotate.tool.cwl/outLcaName"
                }, 
                {
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "doc": "Output expanded ontology sim file (protein mode only)", 
                    "inputBinding": {
                        "prefix": "--out_ontology"
                    }, 
                    "id": "#sims_annotate.tool.cwl/outOntologyName"
                }, 
                {
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "doc": "Output expanded rna sim file (rna mode only)", 
                    "inputBinding": {
                        "prefix": "--out_rna"
                    }, 
                    "id": "#sims_annotate.tool.cwl/outRnaName"
                }, 
                {
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "doc": "Verbose logging mode", 
                    "inputBinding": {
                        "prefix": "--verbose"
                    }, 
                    "id": "#sims_annotate.tool.cwl/verbose"
                }
            ], 
            "baseCommand": [
                "sims_annotate.pl"
            ], 
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
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "doc": "Output expanded protein sim file (protein mode only)", 
                    "outputBinding": {
                        "glob": "$(inputs.outExpandName)"
                    }, 
                    "id": "#sims_annotate.tool.cwl/outExpand"
                }, 
                {
                    "type": "File", 
                    "doc": "Output filtered similarity file", 
                    "outputBinding": {
                        "glob": "$(inputs.outFilterName)"
                    }, 
                    "id": "#sims_annotate.tool.cwl/outFilter"
                }, 
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "doc": "Output expanded LCA file (protein and rna mode)", 
                    "outputBinding": {
                        "glob": "$(inputs.outLcaName)"
                    }, 
                    "id": "#sims_annotate.tool.cwl/outLca"
                }, 
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "doc": "Output expanded ontology sim file (protein mode only)", 
                    "outputBinding": {
                        "glob": "$(inputs.outOntologyName)"
                    }, 
                    "id": "#sims_annotate.tool.cwl/outOntology"
                }, 
                {
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "doc": "Output expanded rna sim file (rna mode only)", 
                    "outputBinding": {
                        "glob": "$(inputs.outRnaName)"
                    }, 
                    "id": "#sims_annotate.tool.cwl/outRna"
                }
            ], 
            "id": "#sims_annotate.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "label": "GNU sort", 
            "doc": "sort text file base on given field(s)", 
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
            "stdout": "sort.log", 
            "stderr": "sort.error", 
            "inputs": [
                {
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "doc": "-t, --field-separator=SEP\nuse SEP instead of non-blank to blank transition\n", 
                    "inputBinding": {
                        "prefix": "-t", 
                        "valueFrom": "$(\"\\u0009\")"
                    }, 
                    "id": "#sort.tool.cwl/field"
                }, 
                {
                    "type": "File", 
                    "doc": "File to sort", 
                    "format": [
                        "#sort.tool.cwl/input/FileFormats.cv.yamltsv"
                    ], 
                    "inputBinding": {
                        "position": 1
                    }, 
                    "id": "#sort.tool.cwl/input"
                }, 
                {
                    "type": "string", 
                    "inputBinding": {
                        "prefix": "-k"
                    }, 
                    "doc": "-k, --key=POS1[,POS2]\nstart a key at POS1, end it at POS2 (origin 1)\n", 
                    "id": "#sort.tool.cwl/key"
                }, 
                {
                    "type": "string", 
                    "doc": "-o, --output=FILE\nwrite result to FILE instead of standard output\n", 
                    "inputBinding": {
                        "prefix": "-o"
                    }, 
                    "id": "#sort.tool.cwl/outName"
                }
            ], 
            "baseCommand": [
                "sort"
            ], 
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
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "doc": "The sorted file", 
                    "outputBinding": {
                        "glob": "$(inputs.outName)"
                    }, 
                    "id": "#sort.tool.cwl/output"
                }
            ], 
            "id": "#sort.tool.cwl"
        }, 
        {
            "class": "CommandLineTool", 
            "label": "sortmerna", 
            "doc": "align rRNA fasta file against clustered rRNA index\noutput in blast m8 format\n>sortmerna -a <# core> -m <MB ram> -e 0.1 --blast '1 cigar qcov qstrand' --ref '<refFasta>,<indexDir>/<indexName>' --reads <input> --aligned <input basename>\n", 
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
            "stdout": "sortmerna.log", 
            "stderr": "sortmerna.error", 
            "inputs": [
                {
                    "type": [
                        "null", 
                        "float"
                    ], 
                    "doc": "E-value threshold, default 0.1", 
                    "default": 0.1, 
                    "inputBinding": {
                        "prefix": "-e"
                    }, 
                    "id": "#sortmerna.tool.cwl/evalue"
                }, 
                {
                    "type": [
                        "null", 
                        "Directory"
                    ], 
                    "doc": "Directory containing index files with prefix INDEXNAME", 
                    "default": "./", 
                    "id": "#sortmerna.tool.cwl/indexDir"
                }, 
                {
                    "type": "string", 
                    "doc": "Prefix for index files", 
                    "id": "#sortmerna.tool.cwl/indexName"
                }, 
                {
                    "type": "File", 
                    "doc": "Input file, sequence (fasta/fastq)", 
                    "format": [
                        "#sortmerna.tool.cwl/input/FileFormats.cv.yamlfasta", 
                        "#sortmerna.tool.cwl/input/FileFormats.cv.yamlfastq"
                    ], 
                    "inputBinding": {
                        "prefix": "--reads"
                    }, 
                    "id": "#sortmerna.tool.cwl/input"
                }, 
                {
                    "type": "File", 
                    "doc": "Reference .fasta file", 
                    "id": "#sortmerna.tool.cwl/refFasta"
                }
            ], 
            "baseCommand": [
                "sortmerna"
            ], 
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
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "doc": "Output tab separated aligned file", 
                    "outputBinding": {
                        "glob": "$(inputs.input.basename).blast"
                    }, 
                    "id": "#sortmerna.tool.cwl/output"
                }
            ], 
            "id": "#sortmerna.tool.cwl"
        }, 
        {
            "class": "Workflow", 
            "label": "preprocess-fastq", 
            "doc": "Remove and trim low quality reads from fastq files. \nReturn fasta files with reads passed this qc steo and reads removed.\n", 
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
                    "type": "string", 
                    "id": "#preprocess-fastq.workflow.cwl/jobid"
                }, 
                {
                    "type": {
                        "type": "array", 
                        "items": "File"
                    }, 
                    "id": "#preprocess-fastq.workflow.cwl/sequences"
                }
            ], 
            "outputs": [
                {
                    "type": "File", 
                    "outputSource": "#preprocess-fastq.workflow.cwl/rejected2fasta/file", 
                    "id": "#preprocess-fastq.workflow.cwl/rejected"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#preprocess-fastq.workflow.cwl/trimmed2fasta/file", 
                    "id": "#preprocess-fastq.workflow.cwl/trimmed"
                }
            ], 
            "steps": [
                {
                    "run": "#DynamicTrimmer.tool.cwl", 
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
                    ], 
                    "out": [
                        "#preprocess-fastq.workflow.cwl/filter/trimmed", 
                        "#preprocess-fastq.workflow.cwl/filter/rejected"
                    ], 
                    "id": "#preprocess-fastq.workflow.cwl/filter"
                }, 
                {
                    "run": "#seqUtil.tool.cwl", 
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
                    ], 
                    "out": [
                        "#preprocess-fastq.workflow.cwl/rejected2fasta/file"
                    ], 
                    "id": "#preprocess-fastq.workflow.cwl/rejected2fasta"
                }, 
                {
                    "run": "#seqUtil.tool.cwl", 
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
                    ], 
                    "out": [
                        "#preprocess-fastq.workflow.cwl/trimmed2fasta/file"
                    ], 
                    "id": "#preprocess-fastq.workflow.cwl/trimmed2fasta"
                }
            ], 
            "id": "#preprocess-fastq.workflow.cwl"
        }, 
        {
            "class": "Workflow", 
            "label": "rna abundance", 
            "doc": "RNAs - abundace profiles from annotated files", 
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
            "outputs": [
                {
                    "type": "File", 
                    "outputSource": "#rna-abundance.workflow.cwl/lcaProfile/output", 
                    "id": "#rna-abundance.workflow.cwl/lcaProfileOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#rna-abundance.workflow.cwl/md5Profile/output", 
                    "id": "#rna-abundance.workflow.cwl/md5ProfileOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#rna-abundance.workflow.cwl/sourceStats/output", 
                    "id": "#rna-abundance.workflow.cwl/sourceStatsOut"
                }
            ], 
            "steps": [
                {
                    "run": "#sims_abundance.tool.cwl", 
                    "in": [
                        {
                            "source": "#rna-abundance.workflow.cwl/rnaClustMap", 
                            "id": "#rna-abundance.workflow.cwl/lcaProfile/cluster"
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
                    ], 
                    "out": [
                        "#rna-abundance.workflow.cwl/lcaProfile/output"
                    ], 
                    "id": "#rna-abundance.workflow.cwl/lcaProfile"
                }, 
                {
                    "run": "#sims_abundance.tool.cwl", 
                    "in": [
                        {
                            "source": "#rna-abundance.workflow.cwl/rnaClustMap", 
                            "id": "#rna-abundance.workflow.cwl/md5Profile/cluster"
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
                    ], 
                    "out": [
                        "#rna-abundance.workflow.cwl/md5Profile/output"
                    ], 
                    "id": "#rna-abundance.workflow.cwl/md5Profile"
                }, 
                {
                    "run": "#sims_abundance.tool.cwl", 
                    "in": [
                        {
                            "source": "#rna-abundance.workflow.cwl/rnaClustMap", 
                            "id": "#rna-abundance.workflow.cwl/sourceStats/cluster"
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
                    ], 
                    "out": [
                        "#rna-abundance.workflow.cwl/sourceStats/output"
                    ], 
                    "id": "#rna-abundance.workflow.cwl/sourceStats"
                }
            ], 
            "id": "#rna-abundance.workflow.cwl"
        }, 
        {
            "class": "Workflow", 
            "label": "rna annotation", 
            "doc": "RNAs - predict, cluster, identify, annotate", 
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
            "outputs": [
                {
                    "type": "File", 
                    "outputSource": "#rna-annotation.workflow.cwl/formatCluster/output", 
                    "id": "#rna-annotation.workflow.cwl/rnaClustMapOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#rna-annotation.workflow.cwl/rnaCluster/outSeq", 
                    "id": "#rna-annotation.workflow.cwl/rnaClustSeqOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#rna-annotation.workflow.cwl/annotateSims/outRna", 
                    "id": "#rna-annotation.workflow.cwl/rnaExpandOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#rna-annotation.workflow.cwl/rnaFeature/output", 
                    "id": "#rna-annotation.workflow.cwl/rnaFeatureOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#rna-annotation.workflow.cwl/annotateSims/outFilter", 
                    "id": "#rna-annotation.workflow.cwl/rnaFilterOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#rna-annotation.workflow.cwl/annotateSims/outLca", 
                    "id": "#rna-annotation.workflow.cwl/rnaLCAOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#rna-annotation.workflow.cwl/bleachSims/output", 
                    "id": "#rna-annotation.workflow.cwl/rnaSimsOut"
                }
            ], 
            "steps": [
                {
                    "run": "#sims_annotate.tool.cwl", 
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
                    ], 
                    "out": [
                        "#rna-annotation.workflow.cwl/annotateSims/outFilter", 
                        "#rna-annotation.workflow.cwl/annotateSims/outRna", 
                        "#rna-annotation.workflow.cwl/annotateSims/outLca"
                    ], 
                    "id": "#rna-annotation.workflow.cwl/annotateSims"
                }, 
                {
                    "run": "#bleachsims.tool.cwl", 
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
                    ], 
                    "out": [
                        "#rna-annotation.workflow.cwl/bleachSims/output"
                    ], 
                    "id": "#rna-annotation.workflow.cwl/bleachSims"
                }, 
                {
                    "run": "#format_cluster.tool.cwl", 
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
                    ], 
                    "out": [
                        "#rna-annotation.workflow.cwl/formatCluster/output"
                    ], 
                    "id": "#rna-annotation.workflow.cwl/formatCluster"
                }, 
                {
                    "run": "#blat.tool.cwl", 
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
                    ], 
                    "out": [
                        "#rna-annotation.workflow.cwl/rnaBlat/output"
                    ], 
                    "id": "#rna-annotation.workflow.cwl/rnaBlat"
                }, 
                {
                    "run": "#cdhit-est.tool.cwl", 
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
                    ], 
                    "out": [
                        "#rna-annotation.workflow.cwl/rnaCluster/outSeq", 
                        "#rna-annotation.workflow.cwl/rnaCluster/outClstr"
                    ], 
                    "id": "#rna-annotation.workflow.cwl/rnaCluster"
                }, 
                {
                    "run": "#rna_feature.tool.cwl", 
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
                    ], 
                    "out": [
                        "#rna-annotation.workflow.cwl/rnaFeature/output"
                    ], 
                    "id": "#rna-annotation.workflow.cwl/rnaFeature"
                }, 
                {
                    "run": "#sortmerna.tool.cwl", 
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
                    ], 
                    "out": [
                        "#rna-annotation.workflow.cwl/sortmerna/output"
                    ], 
                    "id": "#rna-annotation.workflow.cwl/sortmerna"
                }, 
                {
                    "run": "#seqUtil.tool.cwl", 
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
                    ], 
                    "out": [
                        "#rna-annotation.workflow.cwl/sortseq/file"
                    ], 
                    "id": "#rna-annotation.workflow.cwl/sortseq"
                }, 
                {
                    "run": "#sort.tool.cwl", 
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
                    ], 
                    "out": [
                        "#rna-annotation.workflow.cwl/sorttab/output"
                    ], 
                    "id": "#rna-annotation.workflow.cwl/sorttab"
                }
            ], 
            "id": "#rna-annotation.workflow.cwl"
        }, 
        {
            "class": "Workflow", 
            "label": "rna full analysis", 
            "doc": "RNAs - preprocess, annotation, abundance", 
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
            "inputs": [
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
                        "type": "array", 
                        "items": "File"
                    }, 
                    "id": "#main/sequences"
                }
            ], 
            "outputs": [
                {
                    "type": "File", 
                    "outputSource": "#main/rnaAbundance/lcaProfileOut", 
                    "id": "#main/lcaProfileOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/rnaAbundance/md5ProfileOut", 
                    "id": "#main/md5ProfileOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/preProcess/rejected", 
                    "id": "#main/preProcessRejected"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/preProcess/trimmed", 
                    "id": "#main/preProcessTrimmed"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/rnaAnnotate/rnaClustMapOut", 
                    "id": "#main/rnaClustMapOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/rnaAnnotate/rnaClustSeqOut", 
                    "id": "#main/rnaClustSeqOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/rnaAnnotate/rnaFeatureOut", 
                    "id": "#main/rnaFeatureOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/rnaAnnotate/rnaFilterOut", 
                    "id": "#main/rnaFilterOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/rnaAnnotate/rnaSimsOut", 
                    "id": "#main/rnaSimsOut"
                }, 
                {
                    "type": "File", 
                    "outputSource": "#main/rnaAbundance/sourceStatsOut", 
                    "id": "#main/sourceStatsOut"
                }
            ], 
            "steps": [
                {
                    "run": "#preprocess-fastq.workflow.cwl", 
                    "in": [
                        {
                            "source": "#main/jobid", 
                            "id": "#main/preProcess/jobid"
                        }, 
                        {
                            "source": "#main/sequences", 
                            "id": "#main/preProcess/sequences"
                        }
                    ], 
                    "out": [
                        "#main/preProcess/trimmed", 
                        "#main/preProcess/rejected"
                    ], 
                    "id": "#main/preProcess"
                }, 
                {
                    "run": "#rna-abundance.workflow.cwl", 
                    "in": [
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
                    ], 
                    "out": [
                        "#main/rnaAbundance/md5ProfileOut", 
                        "#main/rnaAbundance/lcaProfileOut", 
                        "#main/rnaAbundance/sourceStatsOut"
                    ], 
                    "id": "#main/rnaAbundance"
                }, 
                {
                    "run": "#rna-annotation.workflow.cwl", 
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
                    ], 
                    "out": [
                        "#main/rnaAnnotate/rnaFeatureOut", 
                        "#main/rnaAnnotate/rnaClustSeqOut", 
                        "#main/rnaAnnotate/rnaClustMapOut", 
                        "#main/rnaAnnotate/rnaSimsOut", 
                        "#main/rnaAnnotate/rnaFilterOut", 
                        "#main/rnaAnnotate/rnaExpandOut", 
                        "#main/rnaAnnotate/rnaLCAOut"
                    ], 
                    "id": "#main/rnaAnnotate"
                }
            ], 
            "id": "#main"
        }
    ]
}