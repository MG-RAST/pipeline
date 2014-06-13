#!/usr/bin/env perl

#input: fasta
#outputs:  ${out_prefix}.faa, ${out_prefix}.fna

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use Cwd;
umask 000;

# options
my $out_prefix = "genecall";
my $fasta   = "";
my $proc    = 8;
my $size    = 100;
my $type    = "454";
my $help    = 0;
my $options = GetOptions (
        "out_prefix=s" => \$out_prefix,
        "input=s" => \$fasta,
		"proc:i"  => \$proc,
		"size:i"  => \$size,
		"type:s"  => \$type,
        "help!"   => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($fasta)==0){
    print STDERR "ERROR: An input file was not specified.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! -e $fasta){
    print STDERR "ERROR: The input sequence file [$fasta] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}

my %types = (sanger => 'sanger_10', 454 => '454_30', illumina => 'illumina_10', complete => "complete");
unless (exists $types{$type}) {
    print STDERR "ERROR: The input type [$type] is not supported.\n";
    print STDERR get_usage();
    exit 1;
}

my $run_dir = getcwd;
PipelineAWE::run_cmd("parallel_FragGeneScan.py -v -p $proc -s $size -t $types{$type} -d $run_dir $fasta $out_prefix");

exit 0;

sub get_usage {
    return "USAGE: awe_genecalling.pl -input=<input fasta> [-out_prefix=<output prefix> -type=<454 | sanger | illumina | complete> -proc=<number of threads, default: 8> -size=<size, default: 100>]\noutputs: \${out_prefix}.faa, \${out_prefix}.fna\n";
}
