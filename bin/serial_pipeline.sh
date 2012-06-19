#!/bin/sh

if [ $# -ne 3 ]; then
    echo "USAGE: serial_pipeline.sh <input file> <output dir> <temp dir>"
    echo "produces following files in <output dir>:"
    echo "    <input prefix>.bowtie.passed.fasta"
    echo "    <input prefix>.filter.passed.fasta"
    echo "    <input prefix>.derep.passed.fasta"
    echo "    <input prefix>.search.rna.fasta"
    echo "    <input prefix>.cluster.rna.fasta"
    echo "    <input prefix>.cluster.rna.mapping"
    echo "    <input prefix>.blat.rna.sims"
    echo "    <input prefix>.genecalling.fasta"
    echo "    <input prefix>.cluster.aa.fasta"
    echo "    <input prefix>.cluster.aa.mapping"
    echo "    <input prefix>.blat.aa.sims"
    echo "requires QIIME enviroment and the following programs in PATH:"
    echo "    seqUtil"
    echo "    bowtie"
    echo "    seq_length_stats.py"
    echo "    filter_sequences"
    echo "    DynamicTrimmer.pl"
    echo "    dereplication"
    echo "    dereplication_create_prefix_file"
    echo "    dereplication_from_list"
    echo "    run_FragGeneScan.pl"
    echo "    qiime-uclust"
    echo "    process_clusters"
    echo "    blat"
    echo "    bleachsims"
    exit 1
fi

FASTA=$1
ODIR=$2
TDIR=$3
PREF=`echo $FASTA | awk -F'/' '{print $NF}'`
PREF=${PREF%.*}
M5NR1=/mcs/bio/mg-rast/data/md5nr/current/md5nr.1
M5NR2=/mcs/bio/mg-rast/data/md5nr/current/md5nr.2
M5RNA=/mcs/bio/mg-rast/data/md5rna/current/md5nr
M5RNACL=/mcs/bio/mg-rast/data/md5rna/current/md5nr.clust
BINDEX=/mcs/bio/mg-rast/data/bowtie/index/h_sapiens_asm

echo Start: `date`

### human screen
seqUtil --bowtie_truncate -i $FASTA -o $TDIR/$PREF.input.trunc
diff $FASTA $TDIR/$PREF.input.trunc > $TDIR/$PREF.input.diff
if [ -s $TDIR/$PREF.input.diff ]; then
    seqUtil --sortbyid -t $TDIR -i $FASTA -o $TDIR/$PREF.input.idsort
    BOWIN=$TDIR/$PREF.input.trunc
else
    BOWIN=$FASTA
fi
bowtie --suppress 5,6 -p 8 --al $TDIR/$PREF.bowtie.align.fasta --un $TDIR/$PREF.bowtie.unalign.fasta -f -t $BINDEX $BOWIN | cut -f1 | sort -u > $TDIR/$PREF.bowtie.align.ids
if [ -s $TDIR/$PREF.input.idsort ]; then
    seqUtil --remove_seqs -i $TDIR/$PREF.input.idsort -o $ODIR/$PREF.bowtie.passed.fasta -l $TDIR/$PREF.bowtie.align.ids
    rm $TDIR/$PREF.input.idsort
    rm $TDIR/$PREF.bowtie.unalign.fasta
else
    mv $TDIR/$PREF.bowtie.unalign.fasta $ODIR/$PREF.bowtie.passed.fasta
fi
rm $TDIR/$PREF.input.trunc
rm $TDIR/$PREF.input.diff
rm $TDIR/$PREF.bowtie.align.fasta
rm $TDIR/$PREF.bowtie.align.ids

### QC steps (input from screen passed)
# 1. seq filter
seq_length_stats.py -i $ODIR/$PREF.bowtie.passed.fasta -o $TDIR/$PREF.input.stats -f
AVGLEN=`grep '^average_length' $TDIR/$PREF.input.stats | cut -f2`
STDEVL=`grep '^standard_deviation_length' $TDIR/$PREF.input.stats | cut -f2`
RANGE=`echo $STDEVL \* 2.0 | bc`
MINLEN=`echo $AVGLEN - $RANGE | bc | cut -f1 -d"."`
MAXLEN=`echo $AVGLEN + $RANGE | bc | cut -f1 -d"."`
filter_sequences -r /dev/null -i $ODIR/$PREF.bowtie.passed.fasta -o $ODIR/$PREF.filter.passed.fasta -filter_ln -min_ln $MINLEN -max_ln $MAXLEN -filter_ambig -max_ambig 0
rm $TDIR/$PREF.input.stats

# 2. dereplication
dereplication -p 50 -f $ODIR/$PREF.filter.passed.fasta -dest $TDIR -m 2500M -t $TDIR
cut -f1,2 $TDIR/$PREF.filter.passed.fasta.prefix_50.sorted > $ODIR/$PREF.derep.mapping
mv $TDIR/$PREF.filter.passed.fasta.derep.fasta $ODIR/$PREF.derep.passed.fasta
rm $TDIR/$PREF.filter.passed.fasta.derep.ids
rm $TDIR/$PREF.filter.passed.fasta.removed.ids
rm $TDIR/$PREF.filter.passed.fasta.removed.fasta
rm $TDIR/$PREF.filter.passed.fasta.prefix_50
rm $TDIR/$PREF.filter.passed.fasta.prefix_50.sorted

### rna steps (input from screen passed)
# 1. search
qiime-uclust --mergesort $ODIR/$PREF.bowtie.passed.fasta --output $TDIR/$PREF.input.seqsort --tmpdir $TDIR
qiime-uclust --input $TDIR/$PREF.input.seqsort --lib $M5RNACL --uc $TDIR/$PREF.search.rna.uc --id 0.7 --rev --tmpdir $TDIR
qiime-uclust --input $TDIR/$PREF.input.seqsort --uc2fasta $TDIR/$PREF.search.rna.uc --output $ODIR/$PREF.search.rna.fasta --types H --origheader --tmpdir $TDIR
rm $TDIR/$PREF.search.rna.uc

# 2. cluster
qiime-uclust --input $TDIR/$PREF.input.seqsort --uc $TDIR/$PREF.cluster.rna.uc --id 0.97 --rev --tmpdir $TDIR
qiime-uclust --input $TDIR/$PREF.input.seqsort --uc2fasta $TDIR/$PREF.cluster.rna.uc --types SH --output $TDIR/$PREF.cluster.rna.uc.fasta --tmpdir $TDIR
process_clusters -u $TDIR/$PREF.cluster.rna.uc.fasta -p rna97_ -m $ODIR/$PREF.cluster.rna.mapping -f $ODIR/$PREF.cluster.rna.fasta
rm $TDIR/$PREF.input.seqsort
rm $TDIR/$PREF.cluster.rna.uc
rm $TDIR/$PREF.cluster.rna.uc.fasta

# 3. blat
blat -out=blast8 -t=dna -q=dna -fastMap $M5RNA $ODIR/$PREF.cluster.rna.fasta stdout | bleachsims -s stdin -o $ODIR/$PREF.blat.rna.sims -c 3 -m 10 -r 0

### protein steps (input from QC passed)
# 1. genecalling
run_FragGeneScan.pl -genome $ODIR/$PREF.derep.passed.fasta -out $TDIR/$PREF.genecalling -complete 0 -train 454_30
mv $TDIR/$PREF.genecalling.faa $ODIR/$PREF.genecalling.fasta
rm $TDIR/$PREF.genecalling.ffn
rm $TDIR/$PREF.genecalling.out

# 2. cluster
qiime-uclust --mergesort $ODIR/$PREF.genecalling.fasta --output $TDIR/$PREF.genecalling.seqsort --tmpdir $TDIR
qiime-uclust --input $TDIR/$PREF.genecalling.seqsort --uc $TDIR/$PREF.cluster.aa.uc --id 0.9 --rev --tmpdir $TDIR
qiime-uclust --input $TDIR/$PREF.genecalling.seqsort --uc2fasta $TDIR/$PREF.cluster.aa.uc --types SH --output $TDIR/$PREF.cluster.aa.uc.fasta --tmpdir $TDIR
process_clusters -u $TDIR/$PREF.cluster.aa.uc.fasta -p aa90_ -m $ODIR/$PREF.cluster.aa.mapping -f $ODIR/$PREF.cluster.aa.fasta
rm $TDIR/$PREF.genecalling.seqsort
rm $TDIR/$PREF.cluster.aa.uc
rm $TDIR/$PREF.cluster.aa.uc.fasta

# 3. blat
blat -prot -out=blast8 $M5NR1 $ODIR/$PREF.cluster.aa.fasta stdout | bleachsims -s stdin -o $TDIR/$PREF.blat.aa.sims.1 -c 3 -m 10 -r 0
blat -prot -out=blast8 $M5NR2 $ODIR/$PREF.cluster.aa.fasta stdout | bleachsims -s stdin -o $TDIR/$PREF.blat.aa.sims.2 -c 3 -m 10 -r 0
cat $TDIR/$PREF.blat.aa.sims.1 $TDIR/$PREF.blat.aa.sims.2 > $ODIR/$PREF.blat.aa.sims

echo Done: `date`
