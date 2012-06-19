#!/bin/sh

if [ $# != 4 ] || [ $1 == "-h" ]; then
    echo "USAGE: kmerhistogram.sh <tmp dir> <kmer size> <input fasta file> <output hist file>"
    exit 1
fi

TMP_NAME=`date +%s%N | md5sum | cut -f1 -d" "`
count-kmers -S -k $2 -f $3 2> /dev/null | cut -f2 | sort -n | uniq -c | awk '{print $2 "\t" $1;}' > $1/$TMP_NAME.kmers
plotcuml.py -i $1/$TMP_NAME.kmers -o $4
rm $1/$TMP_NAME.kmers
