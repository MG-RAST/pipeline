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
my $aa      = "";
my $rna     = "";
my $pid     = "";
my $ver     = "";
my $help    = "";
my $job_num = "000";
my $stage_id = "";
my $nodes   = 4;
my $size    = 250;
my $stage_name = "cluster";
my $options = GetOptions ("input=s" => \$fasta_file,
                          "output=s"=> \$final_output,
                          "nodes=i" => \$nodes,
			  "size=i"  => \$size,
                          "aa"      => \$aa,
                          "rna"     => \$rna,
                          "pid=i"   => \$pid,
			  "jobnum=s" => \$job_num,
                          "version" => \$ver,
                          "help"    => \$help
                         );

if ( $help or !($fasta_file) ) {
  print STDERR "must specify a input fasta file\n";
  print_usage();
  exit(1);
} elsif ( !($aa xor $rna) ) {
  print STDERR "must select either -aa or -rna\n";
  print_usage();
  exit(1);
} elsif ( ! $pid ) {
  print STDERR "       must enter -pid as int, eg. 80 for 80% identity.\n";
  print_usage();
  exit(1);
}

system("rm -rf tmp_dir");
system("mkdir -p tmp_dir") == 0 or exit (__LINE__);

my ($code, $fext);
if ($aa) {
  ($stage_id, $code, $fext) = (550, "aa", "faa");
} elsif ($rna) {
  ($stage_id, $code, $fext) = (440, "rna", "fna");
}

my $input_fasta = $stage_id.".".$stage_name.".input.$fext";
my $prefix  = $stage_id.".".$stage_name.".$code$pid";

if ((-s $fasta_file) > 1024) {
  system("cp $fasta_file $input_fasta >> cp.out 2>&1") == 0 or exit __LINE__;
  my $ret = system("$runcmd -v -p $nodes -s $size -i $pid -d tmp_dir -t $code $input_fasta $prefix >> $runcmd.out 2>&1");
  if ($ret != 0) {  #clust is skiptable if it fails, move input to output and make an empty mapping file
      system("cp $input_fasta $prefix.$fext");
      system("touch $prefix.mapping");
  } else {
     if ((-s $prefix.$fext) == 0) {
        system("cp $input_fasta $prefix.$fext");
        system("touch $prefix.mapping");
     }
  }
} else {
  # too small, skip the cluster step
  system("cp $input_fasta $prefix.$fext");
  system("touch $prefix.mapping");
}

# rename output to specified name
if (length($final_output) > 0) {
    system("mv $prefix.$fext $final_output") ==0  or exit (__LINE__);
    my $pos=rindex($final_output,".");
    my $stem=substr($final_output,0,$pos);
    system("mv $prefix.mapping $stem.mapping") ==0  or exit (__LINE__);
}

system("rm -rf tmp_dir");

exit(0);

sub print_usage{
    print "USAGE: awe_cluster_parallel.pl -input=<input_fasta> <-aa|-rna> -pid=<percentage of identification, e.g. 80 for 80%>  [-output=<output_fasta> -jobnum=<job_num> -node=<# of nodes> -size=<size>]\n";
}
