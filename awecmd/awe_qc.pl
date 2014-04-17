#!/usr/bin/env perl 

use strict;
use warnings;
no warnings('once');

use List::Util qw(first max min sum);
use Getopt::Long;
use File::Copy;
use Cwd;
umask 000;

# options
my $infile = "";
my $name   = "raw";
my $procs  = 8;
my $kmers  = '15,6';
my $output_prefix = "";
my $assembled = 0;
my $help = 0;
my $filter_options = "";
my $options = GetOptions (
		"input=s"  => \$infile,
		"name=s"   => \$name,
		"procs=i"  => \$procs,
		"kmers=s"  => \$kmers,
		"out_prefix=s"  => \$output_prefix,
        "assembled=i" => \$assembled,
        "filter_options=s" => \$filter_options,
		"help!"    => \$help,
);

if ($help){
    print_usage();
    exit 0;
}elsif (length($infile)==0){
    print "ERROR: An input file was not specified.\n";
    print_usage();
    exit __LINE__;
}elsif (! -e $infile){
    print "ERROR: The input sequence file [$infile] does not exist.\n";
    print_usage();
    exit __LINE__;  
}elsif ($infile !~ /\.(fna|fasta|fq|fastq)$/i) {
    print "ERROR: The input sequence file must be fasta or fastq format.\n";
    print_usage();
    exit __LINE__;
}

unless (length($output_prefix) > 0) {
    print "ERROR: An output_prefix is required.\n";
    print_usage();
    exit __LINE__;  
}

my @kmers = split(/,/, $kmers);
my $bad_kmer = 0;
foreach (@kmers) {
  if ($_ !~ /^\d+$/) { $bad_kmer = 1; }
}
if ((@kmers == 0) || $bad_kmer) {
  print "ERROR: invalid kmeer list: $kmers.\n";
  exit(1);
}

my $format = ($infile =~ /\.(fq|fastq)$/) ? 'fastq' : 'fasta';

my %value_opts = ();
for my $ov (split ":", $filter_options) {
    if ($ov =~ /=/) {
        my ($option, $value) = split "=", $ov;
        $value_opts{$option} = $value;
    }
}

my $d_stats = $output_prefix.".drisee.stats";
my $d_info  = $output_prefix.".drisee.info";
my $c_stats = $output_prefix.".consensus.stats";
my $run_dir = getcwd;

if ($assembled != 1) {
  # create drisee table
  print "drisee -v -p $procs -t $format -d $run_dir -f $infile $d_stats\n";
  system("drisee -v -p $procs -t $format -d $run_dir -f $infile $d_stats > $d_info 2>&1") == 0 or exit __LINE__;

  # create consensus table
  my $max_ln = 600;
  
  if (exists $value_opts{"max_ln"}) {
      $max_ln = min ($max_ln, $value_opts{"max_ln"});
  } else {
    my @new_stats = `seq_length_stats.py -i $infile -t $format -f`;
    if (@new_stats) {
      chomp @new_stats;
      my $max_line   = first { $_ =~ /^length_max/ } @new_stats;
      my $new_max_ln = (split(/\t/, $max_line))[1];
      $max_ln = min ($max_ln, $new_max_ln);
    } else {
      $max_ln = 100;
    }
  }
  print "consensus.py -v -b $max_ln -t $format -i $infile -o $c_stats\n";
  run_cmd("consensus.py -v -b $max_ln -t $format -i $infile -o $c_stats");
  
} else {
  run_cmd("touch $d_stats");
  run_cmd("touch $d_info");
  run_cmd("touch $c_stats");
}

# create kmer profile
foreach my $len (@kmers) {
  print "kmer-tool -l $len -p $procs -i $infile -t $format -o $output_prefix.kmer.$len.stats -f histo -r -d $run_dir\n";
  run_cmd("kmer-tool -l $len -p $procs -i $infile -t $format -o $output_prefix.kmer.$len.stats -f histo -r -d $run_dir");
}

exit(0);

sub print_usage{
    print "USAGE: awe_qc.pl -input=<input_file> -output_prefix=<prefix> [-procs=<number cpus, default 8>, -kmers=<kmer list, default 6,15>, -assembled=<0 or 1, default 0>]\n";
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
