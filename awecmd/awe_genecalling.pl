#!/usr/bin/env perl 

use strict;
use warnings;
use Cwd;
no warnings('once');

use Getopt::Long;
use File::Copy;
use POSIX qw(strftime);
umask 000;

my $stage_name="genecalling";
my $stage;
my $stage_id = 350;
my $revision = "0";
my $runcmd   = "parallel_FragGeneScan.py";

# options
my $job_num    = "000";
my $fasta_file = "";
my $proc    = 8;
my $size    = 100;
my $type    = "454";
my $ver     = "";
my $help    = "";
my $final_output = "";
my $options = GetOptions ("job=i"   => \$job_num,
			  "input=s" => \$fasta_file,
                          "output=s"     => \$final_output,
			  "proc:i"  => \$proc,
			  "type:s"  => \$type,
			  "version" => \$ver,
			 );

unless (-s $fasta_file) {
  print "inputfile: $fasta_file does not exist or is empty\n";
  print_usage();
  exit __LINE__;
}

my $run_dir = getcwd();

print "run_dir=$run_dir\n";

my %types = (sanger => 'sanger_10', 454 => '454_30', illumina => 'illumina_10', complete => "complete");
my $input_fasta = $stage_id.".".$stage_name.".input.fna";

# run cmd
system("cp $fasta_file $input_fasta >> $runcmd.out 2>&1") == 0 or exit __LINE__;
system("$runcmd -v -p $proc -s $size -t $types{$type} -d $run_dir $input_fasta $job_num >> $runcmd.out 2>&1") == 0 or exit __LINE__;
system("seqUtil --stdfasta -i $job_num.faa -o $job_num.clean.faa");

# copy output to somewhere
if (length($final_output) > 0) {
    system("mv $job_num.clean.faa $final_output") == 0 or exit __LINE__;
}

exit(0);

sub print_usage{
    print "USAGE: awe_genecalling.pl -input=<input fasta> [-train=<454 | sanger | illumina | complete> -proc=<number of threads > -output=<output fasta> -jobnum=<job number>] \n";
}
