#! /usr/bin/env sh

DBDIR=$1


  
if [ -n $DBDIR ]  && [ ! -d $DBDIR ] ; then 
  DBDIR="./"
elif [ ! -n $DBDIR] ; then
  DBDIR="./"
fi  

SHOCK="shock.metagenomics.anl.gov/node"

echo "Downloading DB data to $DBDIR"
`curl "$SHOCK/66fe2976-80fd-4d67-a5cd-051018c49c2b?download" > $DBDIR/e_coli.1.bt2`
`curl "$SHOCK/d0eb4784-2f4a-4093-8731-5fe158365036?download" > $DBDIR/e_coli.2.bt2`
`curl "$SHOCK/75acfaea-bc42-4f02-a014-cdff9f025e2e?download" > $DBDIR/e_coli.3.bt2`
`curl "$SHOCK/f85b745c-0bea-4bac-9fa4-530411f3bc1c?download" > $DBDIR/e_coli.4.bt2`
`curl "$SHOCK/94e7b176-034f-4297-957e-cbcaa7cbc583?download" > $DBDIR/e_coli.rev.1.bt2`
`curl "$SHOCK/d0e023b1-7ada-4d10-beda-9db9a681ed57?download" > $DBDIR/e_coli.rev.2.bt2`
`curl "$SHOCK/c4c76c22-297b-4404-af5c-8cd98e580f2a?download" > $DBDIR/md5rna.clust`
`curl "$SHOCK/1284813a-91d1-42b1-bc72-e74f19e1a0d1?download" > $DBDIR/md5rna`
`curl "$SHOCK/e5dc6081-e289-4445-9617-b53fdc4023a8?download" > $DBDIR/m5nr_v1.bdb`
`curl "$SHOCK/4406405c-526c-4a63-be22-04b7c2d18434?download" > $DBDIR/md5nr.1`
`curl "$SHOCK/65d644a8-55a5-439f-a8b5-af1440472d8d?download" > $DBDIR/md5nr.2`
echo "Done"