{
    "cwlVersion": "v1.0", 
    "$graph": [
        {
            "inputs": [
                {
                    "doc": "<bt2-idx>  Index filename prefix (minus trailing .X.bt2).", 
                    "inputBinding": {
                        "prefix": "-x"
                    }, 
                    "type": [
                        "null", 
                        "string"
                    ], 
                    "id": "#bowtie2.tool.cwl/index"
                }, 
                {
                    "default": "./", 
                    "doc": "Directory containing index files with prefix INDEXNAME", 
                    "type": [
                        "null", 
                        "Directory"
                    ], 
                    "id": "#bowtie2.tool.cwl/indexDir"
                }, 
                {
                    "doc": "Prefix for index files", 
                    "type": "string", 
                    "id": "#bowtie2.tool.cwl/indexName"
                }, 
                {
                    "doc": "write unpaired reads that didn't align to <path>", 
                    "inputBinding": {
                        "prefix": "--un"
                    }, 
                    "type": "string", 
                    "id": "#bowtie2.tool.cwl/outUnaligned"
                }, 
                {
                    "doc": "Fasta file", 
                    "inputBinding": {
                        "prefix": "-U"
                    }, 
                    "type": "File", 
                    "id": "#bowtie2.tool.cwl/sequences", 
                    "format": [
                        "#bowtie2.tool.cwl/sequences/FileFormats.cv.yamlfasta"
                    ]
                }
            ], 
            "requirements": [
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": "${\n  var listing = inputs.indexDir.listing;\n  //listing.push(inputs.myfile);\n\n  var indexFiles = [] ;\n  var regexp = new RegExp(\"^\" + inputs.indexName);\n\n  for (var i in listing) {\n     if (regexp.test(listing[i].basename)) { indexFiles.push(listing[i])}\n  };\n\n  return indexFiles ;\n\n\n }\n"
                }, 
                {
                    "class": "InlineJavascriptRequirement"
                }, 
                {
                    "class": "MultipleInputFeatureRequirement"
                }
            ], 
            "stdout": "bowtie2.log", 
            "doc": "Remove sequences from specified host organism using bowtie2:\n>bowtie2 -f --reorder -p $proc --un $unalignedSequences -x $indexDir/$indexName -U $sequences > /dev/null\" \n", 
            "class": "CommandLineTool", 
            "baseCommand": [
                "bowtie2"
            ], 
            "label": "organism screening", 
            "arguments": [
                "-f", 
                "--reorder", 
                {
                    "prefix": "-p", 
                    "valueFrom": "$(runtime.cores)"
                }, 
                {
                    "prefix": "-x", 
                    "valueFrom": "$(inputs.indexDir.path)$(inputs.indexName)"
                }
            ], 
            "stderr": "bowtie2.error", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#bowtie2.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#bowtie2.tool.cwl/info"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.outUnaligned)"
                    }, 
                    "type": [
                        "null", 
                        "File"
                    ], 
                    "id": "#bowtie2.tool.cwl/unaligned", 
                    "format": "file:///Users/Andi/Development/MG-RAST-Repo/pipeline/CWL/Tools/fasta"
                }
            ], 
            "$namespaces": {
                "Indicies": "BowtieIndices.yaml", 
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#bowtie2.tool.cwl", 
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
                    "valueFrom": "${\n  if ( inputs.sequences.format.split(\"/\").slice(-1)[0] == \"fastq\"  ) { return \"--fastq\"; } else { return \"\" ; }\n}\n"
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
                    "format": "${\n  if (inputs.fasta2tab) { return \"tsv\"}\n  else if (inputs.sortbyid2tab) { return \"tsv\"}\n  else if (inputs.fastq2fasta) { return \"fasta\"}\n  else if (inputs.sequences.format) { return inputs.sequences.format}\n  else { return '' }\n}\n"
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
                    "type": "Directory", 
                    "id": "#main/indexDir"
                }, 
                {
                    "type": "string", 
                    "id": "#main/indexName"
                }, 
                {
                    "type": "string", 
                    "id": "#main/jobid"
                }, 
                {
                    "type": "File", 
                    "id": "#main/sequences"
                }, 
                {
                    "default": "200", 
                    "doc": "Stage ID used by MG-RAST for identification", 
                    "type": "string", 
                    "id": "#main/stage"
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
            "doc": "Remove sequences which align against a reference set. The references are preformatted (index files)", 
            "class": "Workflow", 
            "label": "screen out taxa", 
            "steps": [
                {
                    "out": [
                        "#main/screen/unaligned"
                    ], 
                    "run": "#bowtie2.tool.cwl", 
                    "id": "#main/screen", 
                    "in": [
                        {
                            "source": "#main/indexDir", 
                            "id": "#main/screen/indexDir"
                        }, 
                        {
                            "source": "#main/indexName", 
                            "id": "#main/screen/indexName"
                        }, 
                        {
                            "source": [
                                "#main/jobid", 
                                "#main/stage"
                            ], 
                            "valueFrom": "$(self[0]).$(self[1]).preprocess.passed.fasta", 
                            "id": "#main/screen/outUnaligned"
                        }, 
                        {
                            "source": "#main/truncate/file", 
                            "id": "#main/screen/sequences"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/truncate/file"
                    ], 
                    "run": "#seqUtil.tool.cwl", 
                    "id": "#main/truncate", 
                    "in": [
                        {
                            "default": true, 
                            "id": "#main/truncate/bowtie_truncate"
                        }, 
                        {
                            "source": [
                                "#main/jobid", 
                                "#main/stage"
                            ], 
                            "valueFrom": "$(self[0]).$(self[1]).screen.truncated.fasta", 
                            "id": "#main/truncate/output"
                        }, 
                        {
                            "source": "#main/sequences", 
                            "id": "#main/truncate/sequences"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputSource": "#main/screen/unaligned", 
                    "type": "File", 
                    "id": "#main/passed"
                }
            ], 
            "id": "#main"
        }
    ]
}