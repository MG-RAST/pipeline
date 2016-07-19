#!/bin/bash

set -e
set -x

export TAG=`date +"%Y%m%d"`

# create base
docker rmi mgrast/pipeline-base:latest
docker build --force-rm --no-cache --tag mgrast/pipeline-base:${TAG} mgrast_base
docker tag mgrast/pipeline-base:${TAG} mgrast/pipeline-base:latest

# get ADDs
# wget -O third-party/blat/superblat <superblat URL>
# wget -O third-party/search/usearch <usearch URL>

# create children
cd third-party
for i in *
    do docker build --force-rm --no-cache --tag mgrast/pipeline-${i}:${TAG} ${i}
done
