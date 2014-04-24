#!/usr/bin/env perl

#input: .fna or .fastq 

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use List::Util qw(first max min sum);
use Getopt::Long;
use Cwd;
umask 000;

# options
my $infile = "";
my $name   = "raw";
my $procs  = 8;
my $kmers  = '15,6';
my $out_prefix = "qc";
my $assembled  = 0;
my $filter_options = "";
my $help = 0;
my $options = GetOptions (
		"input=s"  => \$infile,
		"name=s"   => \$name,
		"procs=i"  => \$procs,
		"kmers=s"  => \$kmers,
		"out_prefix=s" => \$out_prefix,
        "assembled=i"  => \$assembled,
        "filter_options=s" => \$filter_options,
		"help!" => \$help,
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($infile)==0){
    print STDERR "ERROR: An input file was not specified.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (! -e $infile){
    print STDERR "ERROR: The input sequence file [$infile] does not exist.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif ($infile !~ /\.(fna|fasta|fq|fastq)$/i) {
    print STDERR "ERROR: The input sequence file must be fasta or fastq format.\n";
    print STDERR get_usage();
    exit __LINE__;
}

my @kmers = split(/,/, $kmers);
my $bad_kmer = 0;
foreach (@kmers) {
  if ($_ !~ /^\d+$/) { $bad_kmer = 1; }
}
if ((@kmers == 0) || $bad_kmer) {
  print STDERR "ERROR: invalid kmeer list: $kmers.\n";
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

my $d_stats = $out_prefix.".drisee.stats";
my $d_info  = $out_prefix.".drisee.info";
my $c_stats = $out_prefix.".consensus.stats";
my $run_dir = getcwd;

if ($assembled != 1) {
  # create drisee table
  PipelineAWE::run_cmd("drisee -v -p $procs -t $format -d $run_dir -f $infile $d_stats > $d_info", 1);

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
  PipelineAWE::run_cmd("consensus.py -v -b $max_ln -t $format -i $infile -o $c_stats");
  
} else {
  PipelineAWE::run_cmd("touch $d_stats");
  PipelineAWE::run_cmd("touch $d_info");
  PipelineAWE::run_cmd("touch $c_stats");
}

# create kmer profile
foreach my $len (@kmers) {
  PipelineAWE::run_cmd("kmer-tool -l $len -p $procs -i $infile -t $format -o $out_prefix.kmer.$len.stats -f histo -r -d $run_dir");
}

exit(0);

sub get_usage {
    return "USAGE: awe_qc.pl -input=<input file> -out_prefix=<output prefix> [-procs=<number cpus, default 8>, -kmers=<kmer list, default 6,15>, -assembled=<0 or 1, default 0>]\n";
}
