Instructions to build MG-RAST docker images
-------------------------------------------

```bash
# use real version number if you prefer
MGRASTVERSION=`date +"%Y%m%d"` 
cd pipeline/dockerfiles/
docker build --tag mgrast/base:${MGRASTVERSION} mgrast_base

# third-party images require "latest", thus make sure that your base image is called "latest"
docker rmi mgrast/base:latest
docker tag mgrast/base:${MGRASTVERSION} mgrast/base:latest

# please copy first usearch binary (http://drive5.com/usearch) into third-party/rna_search
# and superblat binary into superblat directory
cd third-party
for i in * ; do docker build --tag mgrast/${i}:${MGRASTVERSION} ${i} ; done
```
