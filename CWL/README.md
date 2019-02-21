# README

This directory contains tool and workflow definitions in CWL. Tests scripts and data go into the Tests and Data directory.

Running tests:
Download large reference files
```bash
bash CWL/Inputs/DBs/getpredata.sh
```

Working commands
```bash
cwltool --cachedir .cache2 --no-match-user amplicon-fasta.workflow.cwl amplicon-fasta.job.yaml 
cwltool --cachedir .cache2 --no-match-user amplicon-fastq.workflow.cwl amplicon-fastq.job.yaml 

```





