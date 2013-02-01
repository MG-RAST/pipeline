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

my $runcmd   = "qiime-uclust";

#my $log = Pipeline::logger($job_num);

# options
my $fasta_file = "";
my $final_output = "";
my $dna     = "";
my $aa      = "";
my $rna     = "";
my $pid     = "";
my $ver     = "";
my $help    = "";
my $job_num = "550";
my $options = GetOptions ("input=s" => \$fasta_file,
                          "output=s"=> \$final_output,
                          "dna"     => \$dna,
                          "aa"      => \$aa,
                          "rna"     => \$rna,
                          "pid=i"   => \$pid,
			  "jobid=s" => \$job_num,
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

system("mkdir -p temp_dir") == 0 or exit (__LINE__);

my $run_dir = ".";

my ($code, $fext);
if ($dna) {
  ($code, $fext) = ("dna", "fna");
} elsif ($aa) {
  ($code, $fext) = ("aa", "faa");
} elsif ($rna) {
  ($code, $fext) = ("rna", "fna");
}


if ((-s $fasta_file) > 1024) {
  if ( stat($fasta_file)->size > 1073741824 ) {
    system("$runcmd --mergesort $run_dir/$fasta_file --tmpdir temp_dir --output $run_dir/input.sorted >> $run_dir/$runcmd.out 2>&1") == 0 or exit (__LINE__);
  } else {
    system("$runcmd --sort $run_dir/$fasta_file --tmpdir tmp_dir --output $run_dir/input.sorted >> $run_dir/$runcmd.out 2>&1") == 0 or exit (__LINE__);
  }

  system("$runcmd --input $run_dir/input.sorted --uc $run_dir/$job_num.$code$pid.uc --id 0.$pid --tmpdir tmp_dir --rev >> $run_dir/$runcmd.out 2>&1") == 0 or exit (__LINE__);
  system("$runcmd --input $run_dir/input.sorted --uc2fasta $run_dir/$job_num.$code$pid.uc --types SH --output $run_dir/$job_num.$code$pid.$fext --tmpdir tmp_dir >> $run_dir/$runcmd.out 2>&1") == 0 or exit (__LINE__);
  system("process_clusters -u $run_dir/$job_num.$code$pid.$fext -p $code".$pid."_ -m $run_dir/$job_num.$code$pid.mapping -f $run_dir/clusters.$code$pid.$fext >> $run_dir/process_clusters.out 2>&1") == 0 or exit (__LINE__);
}
else {
  # too small
  system("touch $run_dir/clusters.$code$pid.$fext");
  system("touch $run_dir/$job_num.$code$pid.mapping");
}


# rename output to specified name
if (length($final_output) > 0) {
   system("mv $job_num.$code$pid.$fext $final_output") or exit (__LINE__);
}

exit(0);

sub print_usage{
    print "USAGE: awe_qiime_uclust.pl -input=<input_fasta> <-dna|-aa|-rna> pid=<percentage of identification, e.g. 80 for 80%>  [-output=<output_fasta>]  [-jobid=<job_id>]\n";
}