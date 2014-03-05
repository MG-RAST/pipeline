#!/usr/bin/env perl 

use strict;
use warnings;
no warnings('once');

use List::Util qw(first max min sum);
use Getopt::Long;
use File::Copy;
use Cwd;
umask 000;

my $stage_name="qc";
my $stage;
for my $s (@{$Pipeline_Conf::pipeline->{'default'}}) {
  $stage = $s if $s->{name} eq $stage_name; 
}
my $stage_id = '075';
my $revision = "0";

# options
my $job_num = "";
my $seqs    = "";
my $name    = "raw";
my $procs   = 4;
my $kmers   = '15,6';
my $output_prefix = "";
my $assembled = 0;
my $help    = 0;
my $filter_options = "";
my $options = GetOptions ("job=i"    => \$job_num,
			  "seqs=s"   => \$seqs,
			  "name=s"   => \$name,
			  "procs=i"  => \$procs,
			  "kmers=s"  => \$kmers,
			  "out_prefix=s"  => \$output_prefix,
                          "assembled=i" => \$assembled,
                          "filter_options=s" => \$filter_options,
			  "help!"    => \$help,
			 );

unless (-s $seqs) {
    print "ERROR: The input sequence file [$seqs] does not exist.\n";
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

# format
my $format  = '';
my $gzipped = 0;
if ($seqs =~ /^(\S+)\.gz$/) {
  $gzipped = 1;
  $format = ($1 =~ /\.(fq|fastq)$/) ? 'fastq' : 'fasta';
}
else {
  $format = ($seqs =~ /\.(fq|fastq)$/) ? 'fastq' : 'fasta';
}

# files
my $run_dir = getcwd();
my $basename = $run_dir."/".$output_prefix;
my $log_file = $basename.".qc.out";
my $infile   = $basename.".input.".$format;
#my $message  = "$stage_name failed on job: $job_num, see $stage_dir/$stage_id.qc.out for details.";

if ($gzipped) {
  system("zcat $seqs > $infile") == 0 or exit __LINE__;
} else {
  system("cp $seqs $infile") == 0 or exit __LINE__;
}

my %value_opts = ();
my %boolean_opts = ();
for my $ov (split ":", $filter_options) {
    if ($ov =~ /=/) {
      my ($option, $value) = split "=", $ov;
      $value_opts{$option} = $value;
    } else {
      $boolean_opts{$ov} = 1;
    }
}

if($assembled != 1) {
  my $d_stats  = $basename.".drisee.stats";
  # create drisee table
  system("echo 'running drisee ... ' >> $log_file ");
  system("drisee -v -p $procs -t $format -d $run_dir -l $log_file -f $infile $d_stats > $basename.drisee.info 2>&1") == 0 or exit __LINE__;

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
  print "running consensus ...";
  system("echo 'running consensus ... ' >> $log_file ");
  system("consensus.py -v -b $max_ln -t $format -i $infile -o $basename.consensus.stats >> $log_file 2>&1") == 0 or exit __LINE__;
  
  # !!note: following code needs to be moved to "done" stage to write to db
  # load drisee stats
  #my $d_score = 0;
  #if (-s $d_stats) {
  #  $d_score = `head -2 $d_stats | tail -1 | cut -f8`;
  #  chomp $d_score;
  #}
  #my $res = Pipeline::set_job_statistics($job_num, [["drisee_score_$name", sprintf("%.3f", $d_score)]]);
  #unless ($res) {
  #  print "loading drisee_score_$name stat: $d_score\n";
  #}
  ###end of note
} else {
  system("touch $basename.drisee.info");
  system("touch $basename.drisee.stats");
  system("touch $basename.consensus.stats");
}

# create kmer profile
foreach my $len (@kmers) {
  system("echo 'running kmer-tool for size $len ... ' >> $log_file ");
  system("kmer-tool -l $len -p $procs -i $infile -t $format -o $basename.kmer.$len.stats -f histo -r -d $run_dir >> $log_file 2>&1") == 0 or exit __LINE__;
}

exit(0);

sub print_usage{
    print "USAGE: awe_qc.pl -seqs=<input_file> -output_prefix=<prefix> [-procs=<number cpus, default 4>, -kmers=<kmer list, default 6,15>, -assembled=<0 or 1, default 0>]\n";
}


