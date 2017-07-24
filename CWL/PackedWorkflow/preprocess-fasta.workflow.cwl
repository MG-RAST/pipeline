{
    "cwlVersion": "v1.0", 
    "$graph": [
        {
            "inputs": [
                {
                    "doc": "input fasta sequence file", 
                    "inputBinding": {
                        "prefix": "-input"
                    }, 
                    "type": "File", 
                    "id": "#filter_fasta.tool.cwl/sequences", 
                    "format": [
                        "#filter_fasta.tool.cwl/sequences/FileFormats.cv.yamlfasta"
                    ]
                }, 
                {
                    "doc": "input sequence stats file, json format", 
                    "inputBinding": {
                        "prefix": "-stats"
                    }, 
                    "type": "File", 
                    "id": "#filter_fasta.tool.cwl/stats", 
                    "format": [
                        "#filter_fasta.tool.cwl/stats/FileFormats.cv.yamljson"
                    ]
                }
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }
            ], 
            "stdout": "filter_fasta.log", 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#filter_fasta.tool.cwl/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#filter_fasta.tool.cwl/info"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.sequences.basename).passed"
                    }, 
                    "type": "File", 
                    "id": "#filter_fasta.tool.cwl/passed"
                }, 
                {
                    "outputBinding": {
                        "glob": "$(inputs.sequences.basename).removed"
                    }, 
                    "type": "File", 
                    "id": "#filter_fasta.tool.cwl/removed"
                }
            ], 
            "baseCommand": [
                "filter_fasta.pl"
            ], 
            "class": "CommandLineTool", 
            "arguments": [
                {
                    "prefix": "--output", 
                    "valueFrom": "$(inputs.sequences.basename).passed"
                }, 
                {
                    "prefix": "--removed", 
                    "valueFrom": "$(inputs.sequences.basename).removed"
                }
            ], 
            "stderr": "filter_fasta.error", 
            "$namespaces": {
                "Formats": "FileFormats.cv.yaml"
            }, 
            "id": "#filter_fasta.tool.cwl", 
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
                }, 
                {
                    "type": "File", 
                    "id": "#main/stats"
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
            "doc": "", 
            "class": "Workflow", 
            "label": "filter fasta", 
            "steps": [
                {
                    "out": [
                        "#main/filter/passed", 
                        "#main/filter/removed"
                    ], 
                    "run": "#filter_fasta.tool.cwl", 
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
                        }, 
                        {
                            "source": "#main/stats", 
                            "id": "#main/filter/stats"
                        }
                    ]
                }
            ], 
            "outputs": [
                {
                    "outputSource": "#main/filter/passed", 
                    "type": "File", 
                    "id": "#main/passed"
                }, 
                {
                    "outputSource": "#main/filter/removed", 
                    "type": "File", 
                    "id": "#main/removed"
                }
            ], 
            "id": "#main"
        }
    ]
}