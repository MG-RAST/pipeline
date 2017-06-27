#!/bin/bash

# set option
HELP=0
SHOCK=''
NODES=''
TOKEN=''
USAGE="Usage: delete_node.sh [-h] -s <shock url> -n <comma-seperated node IDs> -t <auth token>"

# get options
while getopts hs:n:t: option; do
    case "${option}"
	in
	    h) HELP=1;;
	    s) SHOCK=${OPTARG};;
	    n) NODES=${OPTARG};;
	    t) TOKEN=${OPTARG};;
    esac
done

# check options
if [ $HELP -eq 1 ]; then
    echo $USAGE
    exit 0
fi
if [ -z $NODES ]; then
    echo $USAGE
    exit 1
fi
if [ -z $SHOCK ]; then
    SHOCK='http://shock.metagenomics.anl.gov'
fi
if [ -z $TOKEN ]; then
    if [ -z $MGRAST_WEBKEY ]; then
        echo "[error] missing required MGRAST_WEBKEY enviroment variable"
        exit 1
    fi
    TOKEN=${MGRAST_WEBKEY}
fi

# do it
for N in $(echo $NODES | tr "," " "); do
    curl -s -X DELETE -H "authorization: mgrast $TOKEN" ${SHOCK}/node/${N}
    echo
done