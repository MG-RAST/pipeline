#!/usr/bin/env perl 

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use File::Copy;
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
    print_usage();
    exit 0;
}elsif (length($fasta)==0){
    print "ERROR: An input file was not specified.\n";
    print_usage();
    exit __LINE__;
}elsif (length($output)==0){
    print "ERROR: An output file was not specified.\n";
    print_usage();
    exit __LINE__;
}elsif (! -e $fasta){
    print "ERROR: The input sequence file [$fasta] does not exist.\n";
    print_usage();
    exit __LINE__;
}

my $refdb_dir = ".";
if ($ENV{'REFDBPATH'}) {
  $refdb_dir = "$ENV{'REFDBPATH'}";
}
my $rna_nr_path = $refdb_dir."/".$rna_nr;
unless (-s $rna_nr_path) {
    print "ERROR: rna_nr not exist: $rna_nr_path\n";
    print_usage();
    exit __LINE__;
}

my $run_dir = getcwd;
print "parallel_search.py -v -p $proc -s $size -i 0.$ident -d $run_dir $rna_nr_path $fasta $output\n";
PipelineAWE::run_cmd("parallel_search.py -v -p $proc -s $size -i 0.$ident -d $run_dir $rna_nr_path $fasta $output");

exit(0);

sub print_usage{
    print "USAGE: awe_rna_search.pl -input=<input fasta> [-rna_nr=<rna_nr_file, default: md5nr.clust> -proc=<number of threads, default: 8> -size=<size, default: 100> -output=<output fasta default:425.rna.fna> -ident=<ident percentage, default: 70>] \n";
}
