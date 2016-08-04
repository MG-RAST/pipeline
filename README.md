# pipeline
metagenomic analysis server pipeline scripts 
```bash
export TAG=`date +"%Y%m%d.%H%M"`
docker build --force-rm --no-cache --rm -t mgrast/pipeline:${TAG} .
skycore push mgrast/pipeline:${TAG}
```
