#!/bin/bash

# usage: awe_rna_blat.sh -i  <input_fasta> [-o <output_file>]

RNA_NR=md5rna
OUTPUT=450.rna.sim
# get args
while getopts i:o:n option; do
    case "${option}"
	    in
	    i) INPUT=${OPTARG};;
	    o) OUTPUT=${OPTARG};;
    esac
done

if [ ! -e $INPUT ]; then
    echo "ERROR: input file not found: $INPUT" 
    echo "Usage: awe_rna_blat.sh -i input.fasta -o output.sim"
    exit
fi

# if environment varible $REFDBPATH is configured as a valid path under which the index files can be found
if [ ${REFDBPATH} ]
then 
   RNA_NR_PATH=$REFDBPATH/$RNA_NR
else 
   RNA_NR_PATH=$RNA_NR
fi

#run blat
echo "blat -out=blast8 -t=dna -q=dna -fastMap $RNA_NR_PATH $INPUT stdout | bleachsims -s - -o rna.sim.unsorted -r 0"
blat -out=blast8 -t=dna -q=dna -fastMap $RNA_NR_PATH $INPUT stdout | bleachsims -s - -o rna.sim.unsorted -r 0 >> blat.out 2>&1

echo $OUTPUT

#sort result
echo "sort -T . -t $'\t' -k 1,1 -k 12,12nr -o $OUTPUT rna.sim.unsorted"
sort -T . -t $'\t' -k 1,1 -k 12,12nr -o $OUTPUT rna.sim.unsorted >> sort.out 2>&1
