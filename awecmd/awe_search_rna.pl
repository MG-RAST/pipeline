#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use Cwd;
umask 000;

# options
my $fasta   = "";
my $output  = "";
my $rna_nr  = "md5rna.clust";
my $proc    = 8;
my $size    = 100;
my $ident   = 70;
my $help    = 0;
my $options = GetOptions (
		"input=s"  => \$fasta,
        "output:s" => \$output,
		"rna_nr=s" => \$rna_nr,
		"proc:i"   => \$proc,
		"size:i"   => \$size,
		"ident:i"  => \$ident,
		"help!"    => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($fasta)==0){
    PipelineAWE::logger('error', "input file was not specified");
    exit 1;
}elsif (length($output)==0){
    PipelineAWE::logger('error', "output file was not specified");
    exit 1;
}elsif (! -e $fasta){
    PipelineAWE::logger('error', "input sequence file [$fasta] does not exist");
    exit 1;
}

my $refdb_dir = ".";
if ($ENV{'REFDBPATH'}) {
  $refdb_dir = "$ENV{'REFDBPATH'}";
}
my $rna_nr_path = $refdb_dir."/".$rna_nr;
unless (-s $rna_nr_path) {
    PipelineAWE::logger('error', "rna_nr not exist: $rna_nr_path");
    exit 1;
}

my $run_dir = getcwd;
### use usearch - depricated
# PipelineAWE::run_cmd("parallel_search.py -v -p $proc -s $size -i 0.$ident -d $run_dir $rna_nr_path $fasta $output");
# exit 0;

# use vsearch
PipelineAWE::run_cmd("vsearch --quiet --strand both --usearch_global $fasta --id 0.$ident --db $rna_nr_path --uc $fasta.uc");
PipelineAWE::run_cmd("seqUtil -t $run_dir -i $fasta -o $fasta.sort.tab --sortbyid2tab");
PipelineAWE::run_cmd("sort -T $run_dir -t \t -k 9,9 -o $fasta.sort.uc $fasta.uc");

# uc -> fasta
open(OUT, ">$output") || die "Can't open file $output!\n";
open(STAB, "<$fasta.sort.tab") || die "Can't open file $fasta.sort.tab!\n";
open(SUC, "<$fasta.sort.uc") || die "Can't open file $fasta.sort.uc!\n";

my $seql = <STAB>;
chomp $seql;
my ($id, $seq) = split(/\t/, $seql);

while (my $ucl = <SUC>) {
    chomp $ucl;
    unless ($ucl =~ /^H/) {
        next;
    }
    my @parts = split(/\t/, $ucl);
    my ($qlen, $strand, $qstart, $cigar, $qname) = ($parts[2], $parts[4], $parts[5], $parts[7], $parts[8]);
    my @qname_fields = split(/ /, $qname);
    $qname = $qname_fields[0];
    #my $qlen = cigar_length($cigar); // this number is already in output field
    my $qstop = $qstart + $qlen;
    while ($qname ne $id) {
        $seql = <STAB>;
        unless (defined($seql)) { last; }
        chomp $seql;
        ($id, $seq) = split(/\t/, $seql);
    }
    my $seq_match = substr($seq, $qstart, $qlen);
    print OUT ">${qname}_${qstart}_${qstop}_${strand}\n$seq_match\n";
}

close(SUC);
close(STAB);
close(OUT);

exit 0;

sub cigar_length {
    my ($text) = @_;
    my $len = 0;
    while ($text =~ /([0-9]*)([DMI])/g) {
        if ($2 eq 'I') {
            next;
        }
        if ($1) {
            $len += $1;
        } else {
            $len += 1;
        }
    }
    return $len;
}

sub get_usage {
    return "USAGE: awe_search_rna.pl -input=<input fasta> -output=<output fasta> [-rna_nr=<rna cluster file, default: md5rna.clust> -proc=<number of threads, default: 8> -size=<size, default: 100> -ident=<ident percentage, default: 70>] \n";
}
