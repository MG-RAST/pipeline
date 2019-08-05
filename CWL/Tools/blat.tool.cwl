cwlVersion: v1.0
class: CommandLineTool

label: BLAT
doc: |
    fast sequence search command line tool
    >blat -fastMap -t dna -q rna -out blast8 <database> <query> <output>

hints:
    DockerRequirement:
        dockerPull: mgrast/pipeline:4.03

requirements:
    InlineJavascriptRequirement: {}

stdout: blat.log
stderr: blat.error

inputs:
    database:
        type: File
        doc: Database fasta format file
        inputBinding:
            position: 1
    
    query:
        type: File
        doc: Query fasta format file
        inputBinding:
            position: 2
    
    outName:
        type: string
        doc: Output name
        inputBinding:
            position: 3
    
    dbType:
        type: string
        doc: Database type
        inputBinding:
            prefix: -t=
            separate: False
    
    queryType:
        type: string
        doc: Query type
        inputBinding:
            prefix: -q=
            separate: False
    
    fastMap:
        type: boolean?
        doc: Run for fast DNA/DNA remapping - not allowing introns
        inputBinding:
          prefix: -fastMap


baseCommand: [blat]

arguments:
    - -out=blast8
      
outputs:
    info:
        type: stdout
    error: 
        type: stderr  
    output:
        type: File
        doc: Output tab separated similarity file
        outputBinding: 
            glob: $(inputs.outName)

