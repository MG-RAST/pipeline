{
    "cwlVersion": "v1.0", 
    "$graph": [
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
                    "type": "string", 
                    "id": "#main/jobid"
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
            "doc": "Convert fastq to fasta only", 
            "class": "Workflow", 
            "label": "preprocess - fastq2fasta", 
            "steps": [
                {
                    "out": [
                        "#main/rejected2fasta/file"
                    ], 
                    "run": {
                        "cwlVersion": "v1.0", 
                        "inputs": [
                            {
                                "inputBinding": {
                                    "position": 1
                                }, 
                                "type": "string", 
                                "id": "#main/rejected2fasta/filename"
                            }
                        ], 
                        "baseCommand": [
                            "touch"
                        ], 
                        "outputs": [
                            {
                                "outputBinding": {
                                    "glob": "$(inputs.filename)"
                                }, 
                                "type": "File", 
                                "id": "#main/rejected2fasta/file"
                            }
                        ], 
                        "class": "CommandLineTool"
                    }, 
                    "id": "#main/rejected2fasta", 
                    "in": [
                        {
                            "source": "#main/jobid", 
                            "valueFrom": "$(self).100.preprocess.removed.fasta", 
                            "id": "#main/rejected2fasta/filename"
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
                            "source": "#main/sequences", 
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