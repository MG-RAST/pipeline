#!/usr/bin/env perl 

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
umask 000;

# options
my $fasta     = "";
my $output    = "";
my $rna_nr    = "md5rna";
my $assembled = 0;
my $help      = 0;
my $options   = GetOptions (
		"input=s"     => \$fasta,
        "output:s"    => \$output,
		"rna_nr=s"    => \$rna_nr,
		"assembled=i" => \$assembled,
		"help!"       => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($fasta)==0){
    PipelineAWE::logger('error', "input file was not specified");
    exit 1;
}elsif (length($output)==0){
    PipelineAWE::logger('error', "output file was not specified");
    exit 1;
}elsif (! -e $fasta){
    PipelineAWE::logger('error', "input sequence file [$fasta] does not exist");
    exit 1;
}

my $rna_nr_path = undef ;

if (-s $rna_nr) {
  $rna_nr_path = $rna_nr;
}
else{
  my $refdb_dir = ".";
  if ($ENV{'REFDBPATH'}) {
    $refdb_dir = $ENV{'REFDBPATH'};
  }
  $rna_nr_path = $refdb_dir."/".$rna_nr;
}

unless (-s $rna_nr_path) {
    PipelineAWE::logger('error', "rna_nr not exist: $rna_nr_path");
    exit 1;
}
my $opts = "";
if ($assembled == 0) {
    $opts = "-fastMap ";
}
PipelineAWE::run_cmd("blat -out=blast8 -t=dna -q=dna $opts$rna_nr_path $fasta stdout | bleachsims -s - -o $output -r 0", 1);

exit 0;

sub get_usage {
    return "USAGE: mgrast_blat_rna.pl -input=<input fasta> -output=<output sims> [-rna_nr=<rna nr file, default: md5rna>] \n";
}
