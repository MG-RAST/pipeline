{
    "cwlVersion": "v1.0", 
    "$graph": [
        {
            "class": "CommandLineTool", 
            "baseCommand": [
                "ls", 
                "."
            ], 
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                }, 
                {
                    "class": "InitialWorkDirRequirement", 
                    "listing": "${\n  var listing = inputs.mydir.listing;\n  listing.push(inputs.myfile);\n  return listing;\n }\n"
                }
            ], 
            "stdout": "ls.log", 
            "stderr": "error.log", 
            "inputs": [
                {
                    "type": [
                        {
                            "type": "record", 
                            "name": "#ls.tool.yaml/exclusive_parameters/listingByTime", 
                            "fields": [
                                {
                                    "type": "boolean", 
                                    "inputBinding": {
                                        "prefix": "-ltr"
                                    }, 
                                    "name": "#ls.tool.yaml/exclusive_parameters/listingByTime/longlisting"
                                }
                            ]
                        }, 
                        {
                            "type": "record", 
                            "name": "#ls.tool.yaml/exclusive_parameters/size", 
                            "fields": [
                                {
                                    "type": "boolean", 
                                    "inputBinding": {
                                        "prefix": "-S"
                                    }, 
                                    "name": "#ls.tool.yaml/exclusive_parameters/size/bysize"
                                }
                            ]
                        }
                    ], 
                    "id": "#ls.tool.yaml/exclusive_parameters"
                }, 
                {
                    "type": "Directory", 
                    "id": "#ls.tool.yaml/mydir"
                }, 
                {
                    "type": "File", 
                    "id": "#ls.tool.yaml/myfile"
                }
            ], 
            "outputs": [
                {
                    "type": "stderr", 
                    "id": "#ls.tool.yaml/error"
                }, 
                {
                    "type": "stdout", 
                    "id": "#ls.tool.yaml/output"
                }
            ], 
            "id": "#ls.tool.yaml"
        }, 
        {
            "class": "Workflow", 
            "inputs": [
                {
                    "type": "Directory", 
                    "id": "#main/myDir"
                }, 
                {
                    "type": "File", 
                    "id": "#main/myFile"
                }, 
                {
                    "type": [
                        "null", 
                        "boolean"
                    ], 
                    "default": true, 
                    "id": "#main/sortBySize"
                }
            ], 
            "outputs": [
                {
                    "type": "File", 
                    "outputSource": "#main/getSummary/output", 
                    "id": "#main/summary"
                }
            ], 
            "steps": [
                {
                    "run": "#ls.tool.yaml", 
                    "in": [
                        {
                            "bysize": "sortBySize", 
                            "id": "#main/getSummary/exclusive_parameters"
                        }, 
                        {
                            "source": "#main/myDir", 
                            "id": "#main/getSummary/mydir"
                        }, 
                        {
                            "source": "#main/myFile", 
                            "id": "#main/getSummary/myfile"
                        }
                    ], 
                    "out": [
                        "#main/getSummary/output", 
                        "#main/getSummary/error"
                    ], 
                    "id": "#main/getSummary"
                }
            ], 
            "id": "#main"
        }
    ]
}
