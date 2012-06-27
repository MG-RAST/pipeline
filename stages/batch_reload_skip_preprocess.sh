#!/bin/sh

USER=`whoami`
HOSTNAME=`hostname`
JDIR="/mcs/bio/mg-rast/jobsv3"
AWE="/mcs/bio/mg-rast/awedata/jobs"

if [ $USER != "mgrastprod" ] || [ $HOSTNAME != "berlin.mcs.anl.gov" ]; then
    echo 'probably want to run this as mgrastprod on berlin'
    exit 1
fi

if [ $# -ne 1 ] || [ $1 == "-h" ]; then
    echo "USAGE: batch_reload.sh <file with job numbers>"
    exit 1
fi

for i in `cat $1`
do
    delete_job_from_torque $i
    rm -rf $AWE/$i.results
    rm -f $AWE/$i
    rm -f $JDIR/$i/logs/pipeline.log
    rm -f $JDIR/$i/analysis/*
    rm -rf $JDIR/$i/proc/*
    submit_stages -j $i -o "filter_options=skip&file_type=fna&max_lqb=0&bowtie=0&demultiplex=0&dereplicate=0&rna_only=0&screen_indexes=h_sapiens_asm"
    sleep 1
done
