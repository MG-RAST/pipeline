#!/usr/bin/env perl

#input: fasta
#outputs: ${out_prefix}.passed.fna, ${out_prefix}.passed.fna

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use Cwd;
umask 000;

# options
my $fasta = "";
my $out_prefix = "derep";
my $prefix_size = 50;
my $memsize = "1G";
my $run_derep = 1;
my $help = 0;
my $options = GetOptions (
        "input=s" => \$fasta,
		"out_prefix=s" => \$out_prefix,
		"prefix_length=i" => \$prefix_size,
		"mem_size=s" => \$memsize,
		"dereplicate=i" => \$run_derep,
		"help!" => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($fasta)==0){
    print STDERR "ERROR: An input file was not specified.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (! -e $fasta){
    print STDERR "ERROR: The input sequence file [$fasta] does not exist.\n";
    print STDERR get_usage();
    exit __LINE__;
}

if ($run_derep == 0) {
    PipelineAWE::run_cmd("cp $fasta $out_prefix.passed.fna");
    PipelineAWE::run_cmd("touch $out_prefix.removed.fna");
    exit(0);
}

my $run_dir = getcwd;
PipelineAWE::run_cmd("dereplication.py -l $prefix_size -m $memsize -d $run_dir $fasta $out_prefix");

exit(0);

sub get_usage {
    return "USAGE: awe_dereplicate.pl -input=<input fasta> [-out_prefix=<output prefix> --prefix_length=<INT prefix length>]\n".
           "outputs: \${out_prefix}.passed.fna and \${out_prefix}.removed.fna\n";
}
