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
    print STDERR "ERROR: An input file was not specified.\n";
    print STDERR get_usage();
    exit 1;
}elsif (length($output)==0){
    print STDERR "ERROR: An output file was not specified.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! -e $fasta){
    print STDERR "ERROR: The input sequence file [$fasta] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}

my $refdb_dir = ".";
if ($ENV{'REFDBPATH'}) {
  $refdb_dir = "$ENV{'REFDBPATH'}";
}
my $rna_nr_path = $refdb_dir."/".$rna_nr;
unless (-s $rna_nr_path) {
    print STDERR "ERROR: rna_nr not exist: $rna_nr_path\n";
    print STDERR print_usage();
    exit 1;
}

my $run_dir = getcwd;
PipelineAWE::run_cmd("parallel_search.py -v -p $proc -s $size -i 0.$ident -d $run_dir $rna_nr_path $fasta $output");

exit 0;

sub get_usage {
    return "USAGE: awe_search_rna.pl -input=<input fasta> -output=<output fasta> [-rna_nr=<rna cluster file, default: md5rna.clust> -proc=<number of threads, default: 8> -size=<size, default: 100> -ident=<ident percentage, default: 70>] \n";
}
