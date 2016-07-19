#!/bin/bash

export TAG=`date +"%Y%m%d"`

docker rmi mgrast/pipeline-base:latest

set -e
set -x

docker build --force-rm --no-cache --tag mgrast/pipeline-base:${TAG} mgrast_base

docker tag mgrast/pipeline-base:${TAG} mgrast/pipeline-base:latest

cd third-party
for i in *
    do docker build --force-rm --no-cache --tag mgrast/pipeline-${i}:${TAG} ${i}
done
