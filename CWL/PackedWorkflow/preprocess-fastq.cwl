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
                    "type": "string", 
                    "id": "#main/jobid"
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
                }
            ], 
            "doc": "Remove and trim low quality reads from fastq files. \nReturn fasta files with reads passed this qc steo and reads removed.\n", 
            "class": "Workflow", 
            "label": "preprocess-fastq", 
            "steps": [
                {
                    "out": [
                        "#main/filter/trimmed", 
                        "#main/filter/rejected"
                    ], 
                    "run": "#DynamicTrimmer.tool.cwl", 
                    "id": "#main/filter", 
                    "in": [
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).100.preprocess.length.stats", 
                            "id": "#main/filter/output"
                        }, 
                        {
                            "source": "#main/sequences", 
                            "id": "#main/filter/sequences"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/rejected2fasta/file"
                    ], 
                    "run": "#seqUtil.tool.cwl", 
                    "id": "#main/rejected2fasta", 
                    "in": [
                        {
                            "default": true, 
                            "id": "#main/rejected2fasta/fastq2fasta"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).100.preprocess.removed.fasta", 
                            "id": "#main/rejected2fasta/output"
                        }, 
                        {
                            "source": "#main/filter/rejected", 
                            "id": "#main/rejected2fasta/sequences"
                        }
                    ]
                }, 
                {
                    "out": [
                        "#main/trimmed2fasta/file"
                    ], 
                    "run": "#seqUtil.tool.cwl", 
                    "id": "#main/trimmed2fasta", 
                    "in": [
                        {
                            "default": true, 
                            "id": "#main/trimmed2fasta/fastq2fasta"
                        }, 
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).100.preprocess.passed.fasta", 
                            "id": "#main/trimmed2fasta/output"
                        }, 
                        {
                            "source": "#main/filter/trimmed", 
                            "valueFrom": "${\n  inputs.sequences.format = \"fastq\" ; return inputs.sequences\n}\n", 
                            "id": "#main/trimmed2fasta/sequences"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputSource": "#main/rejected2fasta/file", 
                    "type": "File", 
                    "id": "#main/rejected"
                }, 
                {
                    "outputSource": "#main/trimmed2fasta/file", 
                    "type": "File", 
                    "id": "#main/trimmed"
                }
            ], 
            "id": "#main"
        }
    ]
}