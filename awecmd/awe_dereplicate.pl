#!/usr/bin/env perl 

#input: fasta
#outputs: ${out_prefix}.passed.fna, ${out_prefix}.passed.fna

use strict;
use warnings;
no warnings('once');


use Getopt::Long;
use File::Copy;
use File::Basename;
use Cwd;
use POSIX qw(strftime);
umask 000;

# options
my $fasta_file = "";
my $out_prefix = "derep";
my $prefix_size = 50;
my $memsize = "1G";
my $run_derep = 1;
my $help = "";
my $options = GetOptions (
        "input=s" => \$fasta_file,
		"out_prefix=s" => \$out_prefix,
		"prefix_length=i" => \$prefix_size,
		"mem_size=s" => \$memsize,
		"dereplicate=i" => \$run_derep,
		"help!" => \$help
);

if ($help){
    print_usage();
    exit 0;
}elsif (length($fasta_file)==0){
    print "ERROR: An input file was not specified.\n";
    print_usage();
    exit __LINE__;  #use line number as exit code
}elsif (! -e $fasta_file){
    print "ERROR: The input sequence file [$fasta_file] does not exist.\n";
    print_usage();
    exit __LINE__;   
}

if ($run_derep == 0) {
  run_cmd("cp $fasta_file $out_prefix.passed.fna");
  run_cmd("touch $out_prefix.removed.fna");
  exit (0);
}

my $run_dir = getcwd;
print "dereplication.py -l $prefix_size -m $memsize -d $run_dir $fasta_file $out_prefix\n";
run_cmd("dereplication.py -l $prefix_size -m $memsize -d $run_dir $fasta_file $out_prefix");

exit(0);

sub print_usage{
    print "USAGE: awe_dereplicate.pl -input=<input_fasta> [-out_prefix=<output prefix> --prefix_length=<INT prefix length>]\n";
    print "outputs: \${out_prefix}.passed.fna and \${out_prefix}.removed.fna\n"; 
}

sub run_cmd{
    my ($cmd) = @_;
    my $run = (split(/ /, $cmd))[0];
    system($cmd);
    if ($? != 0) {
        print "ERROR: $run returns value $?\n";
        exit $?;
    }
}
