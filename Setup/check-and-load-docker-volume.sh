#! /usr/bin/env sh
echo Checking for database volume
volume=`docker volume ls | grep pipeline-pre-data`
if [[ "$volume" == "" ]] 
then
    echo Can not find docker volume pipeline-pre-data, creating volume
    docker run -t -v pipeline-pre-data:/DBs -v `pwd`:/pipeline mgrast/pipeline:testing  /pipeline/Setup/getpredata.sh /DBs/
else
    echo Found volume pipeline-pre-data, using it
fi    
