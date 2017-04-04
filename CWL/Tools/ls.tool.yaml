cwlVersion: v1.0
class: CommandLineTool
baseCommand: [ls , .]


requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing: |
      ${
        var listing = inputs.mydir.listing;
        listing.push(inputs.myfile);
        return listing;
       }
    # - entryname: userattr.json
#       entry: |
#         {
#           "stage_id": "075",
#           "stage_name": "qc"
#         }

  
stdout: ls.log
stderr: error.log

inputs:
  mydir:
    type: Directory
  myfile:
    type: File
  exclusive_parameters:
    type:
      - type: record
        name: listingByTime
        fields:
          longlisting:
            type: boolean
            inputBinding:
              prefix: -ltr
      - type: record
        name: size
        fields:
          bysize:
            type: boolean
            inputBinding:
              prefix: -S  
                            
    
outputs:
  output:
    type: stdout
  error: 
    type: stderr  
    

