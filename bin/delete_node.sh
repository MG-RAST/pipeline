#!/bin/bash

# set option
HELP=0
SHOCK=''
NODE=''
TOKEN=''
USAGE="Usage: delete_node.sh [-h] -s <shock url> -n <node ID> -t <auth token>"

# get options
while getopts hs:n:t: option; do
    case "${option}"
	in
	    h) HELP=1;;
	    s) SHOCK=${OPTARG};;
	    n) NODE=${OPTARG};;
	    t) TOKEN=${OPTARG};;
    esac
done

# check options
if [ $HELP -eq 1 ]; then
    echo $USAGE
    exit
fi
if [ -z $NODE ] || [ -z $TOKEN ]; then
    echo $USAGE
    exit
fi
if [ -z $SHOCK ]; then
    SHOCK='http://shock.metagenomics.anl.gov'
fi

# do it
curl -s -X DELETE -H "authorization: mgrast $TOKEN" ${SHOCK}/node/${NODE}
echo