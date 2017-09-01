cwlVersion: v1.0
class: CommandLineTool

label: organism screening
doc:  |
    Remove sequences from specified host organism using bowtie2:
    >bowtie2 -f --reorder -p $proc --un $unalignedSequences -x $indexDir/$indexName -U $sequences > /dev/null" 

hints:
  DockerRequirement:
    dockerPull: mgrast/pipeline:4.03
    # dockerPull: mgrast/bowtie2:1.0
    
requirements:
  InlineJavascriptRequirement: {}
  MultipleInputFeatureRequirement: {}

  
        
stdout: bowtie2.log
stderr: bowtie2.error


inputs:
  sequences:
    type: File
    doc: Fasta file
    format:
      - Formats:fasta
    inputBinding:
      prefix: -U
  indexDir: 
    type: Directory?
    doc: Directory containing index files with prefix INDEXNAME
    default: ./
  indexName: 
    type: string
    doc: Prefix for index files
  outUnaligned:
    type: string
    doc: write unpaired reads that didn't align to <path>
    inputBinding:
      prefix: --un

      
baseCommand: [bowtie2]

arguments:
  - -f 
  - --reorder 
  - prefix: -p
    valueFrom: $(runtime.cores)
  - prefix: -x
    valueFrom: $(inputs.indexDir.path)/$(inputs.indexName)
 

 
outputs:
  info:
    type: stdout
  error: 
    type: stderr  
  unaligned:
    type: File?
    format: fasta
    outputBinding: 
      glob: $(inputs.outUnaligned)
    

$namespaces:
  Formats: FileFormats.cv.yaml
  Indicies: BowtieIndices.yaml
#
# s:license: "https://www.apache.org/licenses/LICENSE-2.0"
# s:copyrightHolder: "MG-RAST"