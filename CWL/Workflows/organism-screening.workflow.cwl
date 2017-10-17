cwlVersion: v1.0
class: Workflow

label: screen out taxa
doc:  Remove sequences which align against a reference set using bowtie2. The references are preformatted (index files)

requirements:
    - class: InlineJavascriptRequirement
    - class: MultipleInputFeatureRequirement

inputs:
    jobid: string
    sequences: File
    indexDir: Directory
    indexName:
        type: string?
        default: h_sapiens

outputs:
    passed:
        type: File
        outputSource: untruncateScreen/file

steps:
    truncate:
        run: ../Tools/seqUtil.tool.cwl
        in:
            sequences: sequences
            bowtieTruncate:
                default: true
            output:
                source: sequences
                valueFrom: $(self.basename).truncate
        out: [file]
    screen:
        run: ../Tools/bowtie2.tool.cwl
        in:
            sequences: truncate/file
            indexDir: indexDir
            indexName: indexName
            outUnaligned:
                source: truncate/file
                valueFrom: $(self.basename).unaligned
        out: [unaligned]
    sortInput:
        run: ../Tools/seqUtil.tool.cwl
        in:
            sequences: sequences
            sortbyid:
                default: true
            output:
                source: sequences
                valueFrom: $(self.basename).sort
        out: [file]
    sortScreenID:
        run: ../Tools/seqUtil.tool.cwl
        in:
            sequences: screen/unaligned
            sortbyid2id:
                default: true
            output:
                source: screen/unaligned
                valueFrom: $(self.basename).ids
        out: [file]
    untruncateScreen:
        run: ../Tools/seqUtil.tool.cwl
        in:
            sequences: sortInput/file
            subsetList: sortScreenID/file
            subsetSeqs:
                default: true
            output:
                source: jobid
                valueFrom: $(self).299.screen.passed.fna
        out: [file]
