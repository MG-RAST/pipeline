#!/usr/bin/env perl 

#this script does memcache search to post process the blat output for both aa and rna, and generate files ready for loaddb

use strict;
use warnings;
no warnings('once');

use Getopt::Long;
use File::Copy;
use File::Basename;
use POSIX qw(strftime);
use Cwd;
umask 000;

my $min_gene_size = 1024;
my $mem_host      = "localhost:11211";
my $mem_key       = '_ach';
my $sort_mem      = 10;
my $procs         = 4;
my $max_seq       = 500000;
my $ver_db=7;
my $stage_name="sims";
my $stage_id = 700;
my $revision = "0";

my $run_dir = getcwd();
my $sort_dir = getcwd();

my $out_prefix = $stage_id;

# options
my $job_id = "";
my $raw_input="";
my $aa_sims  = "";
my $rna_sims = "";
my $clust_aa = "";
my $map_rna = "";
my $abundance_file = ""; 

my $options = GetOptions ("job=s"    => \$job_id,
			  "raw=s"    => \$raw_input,
			  "aa_sims=s"  => \$aa_sims,
			  "rna_sims=s"   => \$rna_sims,
			  "clust_aa=s"   => \$clust_aa,
			  "map_rna=s"    => \$map_rna,
 			  "out_prefix=s" => \$out_prefix,
			  "mem_host=s" => \$mem_host,
			  "mem_key=s" => \$mem_key,
			  "nr_ver=s" => \$ver_db,
			  "abundance_file=s"  =>$abundance_file,
			 );

my $prefix_aa = $out_prefix.".aa";
my $prefix_rna = $out_prefix.".rna";

if ($job_id eq "") {
    print  "Error: job is a required parameter\n";
    print_usage();
    exit __LINE__;
}


unless (-s $raw_input) {
    print  "Error: raw input file: [$raw_input] does not exist or is size zero\n";
    print_usage();
    exit __LINE__;
}

my $input_file_str = "--fasta $raw_input ";


unless (-s $aa_sims || -s $rna_sims) {
    print  "Error: either -aa_sims (\'$aa_sims\') or -rna_sims (\'$rna_sims\') should be non-empty\n";
    print_usage();
    exit __LINE__;
}

if (-s $aa_sims) {
  $input_file_str .= "--aa_sims_file $aa_sims ";
}
if (-s $rna_sims) {
  $input_file_str .= "--rna_sims_file $rna_sims ";
}

if (-s $clust_aa) {
  $input_file_str .= "--clust_aa $clust_aa ";  
}
if (-s $map_rna) {
  $input_file_str .= "--map_rna $map_rna ";
}

my $assembly_abun_opt = "";
if (-e $abundance_file) {
  $assembly_abun_opt = "--abun_file $abundance_file";
}

print "input_file_str=".$input_file_str."\n";

system("sims2annotation --job_id $job_id $input_file_str --sort_dir $sort_dir --run_dir $run_dir --prefix $out_prefix --ver_db $ver_db --mem_host $mem_host --mem_key $mem_key --procs $procs $assembly_abun_opt") == 0 or exit __LINE__;

print "Finished $stage_name on job $job_id\n";

exit(0);

sub print_usage{
    print "USAGE: awe_annotate.pl -job=<job identifier>
                                  -raw=<raw input fasta or fastq>
                                  -aa_sims=<input aa sims file>
				  -rna_sims=<input rna sims file>
				  -clust_aa=<aa clust output>
				  -map_rna=<rna clust map>
				  -mem_host=<memcache host>
				  -nr_ver=<nr db version>
				  [-out_prefix=<prefix for output files>]\n";
}
