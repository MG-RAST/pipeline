# README

This directory contains tool and workflow definitions in CWL. Tests scripts and data go into the Tests and Data directory.



## Main workflows

- amplicon
  - amplicon-fasta.workflow.yaml
  - amplicon-fastq.workflow.yaml
- assembled
  - assembled.workflow.cwl
- metabarcode
  - metabarcode-fasta.workflow.cwl
  - metabarcode-fastq.workflow.cwl
- wgs
  - wgs-fasta.workflow.cwl
  - wgs-fastq.job.yaml
  - wgs-noscreen-fasta.workflow.cwl
  - wgs-noscreen-fastq.job.yaml

## Running tests

1. Download large reference files for tests and pipeline:
```bash
CWL/Inputs/DBs/getpredata.sh
```


## Working commands
```bash
cwltool --cachedir .cache2 --no-match-user amplicon-fasta.workflow.cwl amplicon-fasta.job.yaml 
cwltool --cachedir .cache2 --no-match-user amplicon-fastq.workflow.cwl amplicon-fastq.job.yaml 

```





