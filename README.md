# pipeline
metagenomic analysis server pipeline scripts 
```bash
export TAG=`date +"%Y%m%d.%H%M"`
git clone https://github.com/MG-RAST/pipeline.git
cd pipeline
docker build -t mgrast/pipeline:${TAG} .
skycore push mgrast/pipeline:${TAG}
```
