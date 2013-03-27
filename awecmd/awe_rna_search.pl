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
my $stage_id = "425";
my $runcmd   = "parallel_search.py";

# options
my $job_num = "";
my $fasta   = "";
my $rna_nr  = "md5nr.clust";
my $proc    = 8;
my $size    = 100;
my $ident   = 70;
my $output  = $stage_id."rna.fna";
my $options = GetOptions ("job=i"    => \$job_num,
			  "input=s"  => \$fasta,
                          "output:s" => \$output,
			  "rna_nr=s" => \$rna_nr,
			  "proc:i"   => \$proc,
			  "size:i"   => \$size,
			  "ident:i"  => \$ident,
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
system("$runcmd -v -p $proc -s $size -i 0.$ident -d $run_dir $rna_nr_path $fasta $run_dir/$output >> $run_dir/$runcmd.out 2>&1") == 0 or exit __LINE__;

# update jobcache stage status

exit(0);

sub print_usage{
    print "USAGE: awe_rna_search.pl -input=<input fasta> [-rna_nr=<rna_nr_file, default: md5nr.clust> -proc=<number of threads, default: 8 > -size=<size, default: 100> -output=<output fasta default:425.rna.fna> -ident=<ident percentage, default: 70>] \n";
}
