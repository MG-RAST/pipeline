#!/usr/bin/env perl 

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use File::Copy;
use Cwd;
umask 000;

# options
my $fasta   = "";
my $output  = "";
my $proc    = 8;
my $size    = 100;
my $type    = "454";
my $help    = 0;
my $options = GetOptions (
        "input=s"  => \$fasta,
        "output=s" => \$output,
		"proc:i"   => \$proc,
		"size:i"   => \$size,
		"type:s"   => \$type,
        "help!"    => \$help
);

if ($help){
    print_usage();
    exit 0;
}elsif (length($fasta)==0){
    print "ERROR: An input file was not specified.\n";
    print_usage();
    exit __LINE__;
}elsif (length($output)==0){
    print "ERROR: An output file was not specified.\n";
    print_usage();
    exit __LINE__;
}elsif (! -e $fasta){
    print "ERROR: The input sequence file [$fasta] does not exist.\n";
    print_usage();
    exit __LINE__;
}

my %types = (sanger => 'sanger_10', 454 => '454_30', illumina => 'illumina_10', complete => "complete");
unless (exists $types{$type}) {
    print "ERROR: The input type [$type] is not supported.\n";
    print_usage();
    exit __LINE__;
}

my $run_dir = getcwd;
print "parallel_FragGeneScan.py -v -p $proc -s $size -t $types{$type} -d $run_dir $fasta $output\n";
PipelineAWE::run_cmd("parallel_FragGeneScan.py -v -p $proc -s $size -t $types{$type} -d $run_dir $fasta $output");


system("parallel_FragGeneScan.py -v -p $proc -s $size -t $types{$type} -d $run_dir $input_fasta $out_prefix >> $runcmd.out 2>&1") == 0 or exit __LINE__;

system("seqUtil --stdfasta -i $out_prefix.faa -o $out_prefix.clean.faa") ==0 or system("mv $out_prefix.faa $out_prefix.clean.faa");

if (length($final_output) == 0) {
  $final_output = $out_prefix.".faa";
} 
system("mv $out_prefix.clean.faa $final_output") == 0 or exit __LINE__;
system("mv $out_prefix.ffn $out_prefix.fna")==0 or system("touch $out_prefix.fna");

exit(0);

sub print_usage{
    print "USAGE: awe_genecalling.pl -input=<input fasta> -output=<output faa> [-type=<454 | sanger | illumina | complete> -proc=<number of threads, default: 8> -size=<size, default: 100>]\n";
}
