#!/usr/bin/env perl 

use strict;
use warnings;
no warnings('once');


use Getopt::Long;
use File::Copy;
use File::stat;
use File::Basename;
use POSIX qw(strftime);
umask 000;

my $runcmd   = "parallel_cluster";

#my $log = Pipeline::logger($job_num);

# options
my $fasta_file = "";
my $final_output = "";
my $dna     = "";
my $aa      = "";
my $rna     = "";
my $pid     = "";
my $size    = 250;
my $nodes   = 8;
my $ver     = "";
my $help    = "";
my $job_name = "550";
my $options = GetOptions ("input=s" => \$fasta_file,
                          "output=s"=> \$final_output,
                          "dna"     => \$dna,
                          "aa"      => \$aa,
                          "rna"     => \$rna,
                          "pid=i"   => \$pid,
			  "jobname=s" => \$job_name,
                          "version" => \$ver,
                          "help"    => \$help
                         );

if ( $help or !($fasta_file) ) {
  print STDERR "must specify a input fasta file\n";
  print_usage();
  exit(1);
} elsif ( !($dna xor $aa xor $rna) ) {
  print STDERR "must select either -aa, -dna or -rna\n";
  print_usage();
  exit(1);
} elsif ( ! $pid ) {
  print STDERR "       must enter -pid as int, eg. 80 for 80% identity.\n";
  print_usage();
  exit(1);
}

if (-e "tmp_dir") {
    `rm -rf tmp_dir`;
}
system("mkdir -p tmp_dir") == 0 or exit (__LINE__);

my ($code, $fext);
if ($dna) {
  ($code, $fext) = ("dna", "fna");
} elsif ($aa) {
  ($code, $fext) = ("aa", "faa");
} elsif ($rna) {
  ($code, $fext) = ("rna", "fna");
}

my $prefix = $job_name.$code;

if ((-s $fasta_file) > 1024) {
  system("$runcmd -v -p $nodes -s $size -i $pid -d tmp_dir -t $code $fasta_file $prefix >> $runcmd.out 2>&1") == 0 or exit (__LINE__);
} else {
  # too small
  system("cp $fasta_file $prefix.$fext");
  system("touch $prefix.mapping");
}

# rename output to specified name
if (length($final_output) > 0) {
    system("mv $prefix.$fext $final_output") ==0  or exit (__LINE__);
}

exit(0);

sub print_usage{
    print "USAGE: awe_paralle_clust.pl -input=<input_fasta> <-dna|-aa|-rna> -pid=<percentage of identification, e.g. 80 for 80%>  [-output=<output_fasta> -jobname=<job_name>]\n";
}
