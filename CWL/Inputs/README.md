# Run Test Data

cd /CWL/Data/DBs
bash getpredata.sh

cd /test/assembled
cwl-runner --debug --no-container /CWL/Workflows/assembled.workflow.cwl /CWL/Workflows/assembled.job.yaml

cd /test/metabarcode-fastq
cwl-runner --debug --no-container /CWL/Workflows/metabarcode-fastq.workflow.cwl /CWL/Workflows/metabarcode-fastq.job.yaml

cd /test/metabarcode-fasta
cwl-runner --debug --no-container /CWL/Workflows/metabarcode-fasta.workflow.cwl /CWL/Workflows/metabarcode-fasta.job.yaml

cd /test/amplicon-fastq
cwl-runner --debug --no-container /CWL/Workflows/amplicon-fastq.workflow.cwl /CWL/Workflows/amplicon-fastq.job.yaml

cd /test/amplicon-fasta
cwl-runner --debug --no-container /CWL/Workflows/amplicon-fasta.workflow.cwl /CWL/Workflows/amplicon-fasta.job.yaml

cd /test/wgs-fastq
cwl-runner --debug --no-container /CWL/Workflows/wgs-fastq.workflow.cwl /CWL/Workflows/wgs-fastq.job.yaml

cd /test/wgs-fasta
cwl-runner --debug --no-container /CWL/Workflows/wgs-fasta.workflow.cwl /CWL/Workflows/wgs-fasta.job.yaml

cd /test/wgs-noscreen-fastq
cwl-runner --debug --no-container /CWL/Workflows/wgs-noscreen-fastq.workflow.cwl /CWL/Workflows/wgs-noscreen-fastq.job.yaml

cd /test/wgs-noscreen-fasta
cwl-runner --debug --no-container /CWL/Workflows/wgs-noscreen-fasta.workflow.cwl /CWL/Workflows/wgs-noscreen-fasta.job.yaml

cd /test/wgs-noqc-fasta
cwl-runner --debug --no-container /CWL/Workflows/wgs-noscreen-fasta.workflow.cwl /CWL/Workflows/wgs-noqc-fasta.job.yaml
