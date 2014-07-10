#!/usr/bin/env perl 

use strict;
use warnings;
no warnings('once');

use Getopt::Long;
use File::Copy;
use Cwd;
umask 000;

my $stage_name="search";
my $stage;
my $stage_id = "440";

# options
my $job_num = "";
my $fasta   = "";
my $rna_nr  = "md5rna";
my $proc    = 8;
my $size    = 100;
my $ident   = 70;
my $output  = $stage_id.".rna.sim";
my $options = GetOptions ("job=i"    => \$job_num,
			  "input=s"  => \$fasta,
                          "output:s" => \$output,
			  "rna_nr=s" => \$rna_nr,
			 );

my $refdb_dir = ".";
if ($ENV{'REFDBPATH'}) {
  $refdb_dir = "$ENV{'REFDBPATH'}";
}
 
my $rna_nr_path = "";
$rna_nr_path =  $refdb_dir."/".$rna_nr;
unless (-s $rna_nr_path) {
    print "ERROR: rna_nr not exist: $rna_nr_path\n";
    print_usage();
    exit __LINE__;
}
unless (-s $fasta) {
    print  "input file: [$fasta] does not exist or is size zero\n";
    print_usage();
    exit __LINE__;
}

print "rna_nr_path=".$rna_nr_path."\n"; 

my $run_dir = getcwd();

system("blat -out=blast8 -t=dna -q=dna $rna_nr_path $fasta stdout | bleachsims -s - -o $output -r 0") == 0 or exit __LINE__;

exit(0);

sub print_usage{
    print "USAGE: awe_rna_blat.pl -input=<input fasta> [-rna_nr=<rna_nr_file, default: md5nr.clust> -output=<output fasta default:440.rna.sim>] \n";
}
