cwlVersion: v1.0
class: CommandLineTool



hints:
  DockerRequirement:
    dockerPull: mgrast/pipeline:4.03
    # dockerPull: mgrast/dynamictrimmer:1.0
    
requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing: $(inputs.sequences)

stdout: DynamicTrimmer.log
stderr: DynamicTrimmer.error


# >DynamicTrimmer.pl input_files [-p|probcutoff 0.05] [-h|phredcutoff 13] [-b|bwa] [-sanger -solexa -illumina] [-454]
#
# -p|probcutoff  probability value (between 0 and 1) at which base-calling error is considered too high (default; p = 0.05) *or*
# -h|phredcutoff  Phred score (between 0 and 40) at which base-calling error is considered too high (default 13)
#                 use SolexaQA trimming algorithm (default)
# -b|bwa          use BWA trimming algorithm
# -454            use 454 trimming algorithm
# -sanger         Sanger format (bypasses automatic format detection)
# -solexa         Solexa format (bypasses automatic format detection)
# -illumina       Illumina format (bypasses automatic format detection)
# -n|maxtolerable number of low-quality bases to accept (option for 454 trimming algorithm, default 5)
# -l|length_min   minimum sequence length to not be rejected (default is 50)
#
# Function: takes fastq input_files and performs trimming of the sequences to remove low-quality regions.
# Does not discard any sequences, though makes some of them zero-length.
# Creates output file called input_file.trimmed.fastq and input_file.rejected.fastq.  Refuses to overwrite output file.



        


inputs:
  sequences:
    inputBinding:
      position: 1
    type:
      type: array
      items: File
      inputBinding: 
        valueFrom: $(self.basename)

      
baseCommand: [DynamicTrimmer.pl]

# arguments:
#   - valueFrom: ; sleep 100
#     position: 10
    
outputs: 
  info:
    type: stdout
  error: 
    type: stderr  
  trimmed:
    type: [File]
    format: fastq
    outputBinding: 
      glob: "*.trimmed.fastq"
  rejected:
    type: [File]
    format: fastq
    outputBinding: 
      glob: "*.rejected.fastq"    
    

$namespaces:
  Formats: FileFormats.cv.yaml
#
# s:license: "https://www.apache.org/licenses/LICENSE-2.0"
# s:copyrightHolder: "MG-RAST"