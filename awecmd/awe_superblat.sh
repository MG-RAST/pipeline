#!/bin/bash

# usage: superblat.sh  <input_fasta> [<output_file>]

if [ $# -lt 2 ] ; then
      echo "Usage: awe_superblat.sh <input_fasta> <output_filename>"
      exit 1
fi


# if environment varible $REFDBPATH is configured as a valid path under which the index files can be found
if [ ${REFDBPATH} ]
then 
   DB1=$REFDBPATH/md5nr.1
   DB2=$REFDBPATH/md5nr.2
else 
   DB1=md5nr.1
   DB2=md5nr.2
fi


#run superblat and merge results
superblat -prot -fastMap -out=blast8 $DB1 $1 $1.blat_1 
echo "done with $1 1/2"
superblat -prot -fastMap -out=blast8 $DB2 $1 $1.blat_2 
echo "done with $1 2/2" 
cat $1.blat_1 $1.blat_2 > $1.cat_blat 
rm $1.blat_1 $1.blat_2 

#select best hit for each sequence
echo "sort -t$'\t' -k1,1 -k11,11g ${1}.cat_blat | sort -t$'\t' -u -k1,1 > ${1}.best_hit.blat"
sort -t$'\t' -k1,1 -k11,11g ${1}.cat_blat | sort -t$'\t' -u -k1,1 > ${1}.best_hit.blat

#change file name to the sepcified one (if any)
if [ $# -eq 2 ]
  then
     mv ${1}.best_hit.blat $2
  fi
