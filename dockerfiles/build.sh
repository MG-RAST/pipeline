#!/bin/bash

export MGRASTVERSION=`date +"%Y%m%d"`

docker rmi mgrast/base:latest

set -e
set -x

docker build --no-cache --tag mgrast/base:${MGRASTVERSION} mgrast_base

docker tag mgrast/base:${MGRASTVERSION} mgrast/base:latest

cd third-party
for i in * ; do docker build --no-cache --tag mgrast/${i}:${MGRASTVERSION} ${i} ; done