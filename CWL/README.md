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


To check: 
assembled.workflow.cwl assembled.job.yaml
metabarcode-fasta.workflow.cwl metabarcode-fasta.job.yaml	
metabarcode-fastq.workflow.cwl metabarcode-fastq.job.yaml	
wgs-fasta.workflow.cwl wgs-fasta.job.yaml


Errors:
wgs-fastq.workflow.cwl wgs-fastq.job.yaml
and 
wgs-fasta.workflow.cwl  wgs-fasta.job.yaml

Traceback (most recent call last):
  File "/usr/local/bin/seqUtil", line 372, in <module>
    subset_seqs(opts.input, opts.list, opts.out, opts.check, opts.minimum)
  File "/usr/local/bin/seqUtil", line 224, in subset_seqs
    if len(record.seq) < minimum:
NameError: global name 'record' is not defined


