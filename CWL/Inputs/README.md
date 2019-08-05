# Run Test Data
```
cd /CWL/Inputs/DBs
bash getpredata.sh

mkdir -p /data/assembled
cd /data/assembled
cwl-runner --debug --no-container /CWL/Workflows/assembled.workflow.cwl /CWL/Workflows/assembled.job.yaml

mkdir -p /data/metabarcode-fastq
cd /data/metabarcode-fastq
cwl-runner --debug --no-container /CWL/Workflows/metabarcode-fastq.workflow.cwl /CWL/Workflows/metabarcode-fastq.job.yaml

mkdir -p /data/metabarcode-fasta
cd /data/metabarcode-fasta
cwl-runner --debug --no-container /CWL/Workflows/metabarcode-fasta.workflow.cwl /CWL/Workflows/metabarcode-fasta.job.yaml

mkdir -p /data/amplicon-fastq
cd /data/amplicon-fastq
cwl-runner --debug --no-container /CWL/Workflows/amplicon-fastq.workflow.cwl /CWL/Workflows/amplicon-fastq.job.yaml

mkdir -p /data/amplicon-fasta
cd /data/amplicon-fasta
cwl-runner --debug --no-container /CWL/Workflows/amplicon-fasta.workflow.cwl /CWL/Workflows/amplicon-fasta.job.yaml

mkdir -p /data/wgs-fastq
cd /data/wgs-fastq
cwl-runner --debug --no-container /CWL/Workflows/wgs-fastq.workflow.cwl /CWL/Workflows/wgs-fastq.job.yaml

mkdir -p /data/wgs-fasta
cd /data/wgs-fasta
cwl-runner --debug --no-container /CWL/Workflows/wgs-fasta.workflow.cwl /CWL/Workflows/wgs-fasta.job.yaml

mkdir -p /data/wgs-noscreen-fastq
cd /data/wgs-noscreen-fastq
cwl-runner --debug --no-container /CWL/Workflows/wgs-noscreen-fastq.workflow.cwl /CWL/Workflows/wgs-noscreen-fastq.job.yaml

mkdir -p /data/wgs-noscreen-fasta
cd /data/wgs-noscreen-fasta
cwl-runner --debug --no-container /CWL/Workflows/wgs-noscreen-fasta.workflow.cwl /CWL/Workflows/wgs-noscreen-fasta.job.yaml

mkdir -p /data/wgs-noqc-fasta
cd /data/wgs-noqc-fasta
cwl-runner --debug --no-container /CWL/Workflows/wgs-noscreen-fasta.workflow.cwl /CWL/Workflows/wgs-noqc-fasta.job.yaml
```
