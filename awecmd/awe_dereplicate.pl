#!/usr/bin/env perl 

use strict;
use warnings;
no warnings('once');


use Getopt::Long;
use File::Copy;
use File::Basename;
use POSIX qw(strftime);
umask 000;

my $runcmd   = "dereplication";

# options
my $job_num    = "";
my $fasta_file = "";
my $out_file = "default.derep.fna";
my $prefix_size = 50;
my $memsize = "1G";
my $run_derep = 1;
my $options = GetOptions ("input=s"     => \$fasta_file,
			  "output=s"    => \$out_file,
			  "prefix_length=i" => \$prefix_size,
			  "mem_size=s" => \$memsize,
			  "dereplicate" => \$run_derep,
			 );


#my $log = Pipeline::logger($job_num);

if (length($fasta_file)==0){
    print "ERROR: An input file was not specified.\n";
    print_usage();
    exit __LINE__;  #use line number as exit code
}elsif (! -e $fasta_file){
    print "ERROR: The input genome file [$fasta_file] does not exist.\n";
    print_usage();
    exit __LINE__;   
}

if ($run_derep==0) {
  system("cp $fasta_file $out_file > cp.out 2>&1") == 0 or exit __LINE__;
  exit (0);
}

my ($file,$dir,$ext) = fileparse($fasta_file, qr/\.[^.]*/);
if (length($out_file)==0) {
  $out_file = $dir.$file.".derep.fna";
}

my $results_dir = ".";

my $command = "$runcmd -file $fasta_file -destination $results_dir -prefix_length $prefix_size -memory $memsize";
print $command."\n";
system($command);
if ($? != 0) {print "ERROR: $runcmd returns value $?\n"; exit $?}

# rename output to specified name
system("mv $fasta_file.derep.fasta $out_file");
if ($? != 0) {print "ERROR: failed copy output $?\n"; exit $?}

exit(0);

sub print_usage{
    print "USAGE: awe_dereplicate.pl -input=<input_fasta> [-output=<output_fasta> --prefix_length=<INT prefix length>]\n";
}

