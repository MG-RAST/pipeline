#!/usr/bin/env perl 

#this script does memcache search to post process the blat output for both aa and rna
#it contains operations in original MG-RAST pipeline stage 650  (pipeline_sims) and part of the stage 450 (pipeline_rna)

#input 1: aa_sims: aa.sims
#output for 1: 650.aa.sims.filter, 650.aa.expand.protein, 650.aa.expand.ontology, 650.aa.expand.lca

#input 2: rna_simes: rna.sims
#output for 2: 650.rna.sims.filter, 650.rna.expand.protein, 650.rna.ontology, 650.rna.expand.lca


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
my $memcache_host="localhost:11211";
my $memcache_key="na";
my $stage_name="sims";
my $stage_id = 650;
my $revision = "0";
#my $params   = "--verbose --mem_host ".$memcache_host." --mem_key ".$memcache_key;
my $params   = "--verbose --mem_host ".$memcache_host;

my$prefix_aa = $stage_id.".aa";
my $prefix_rna = $stage_id.".rna";

# options
my $job_num = "100";
my $aa_sims  = "";
my $rna_sims = "";
my $options = GetOptions ("job=i"    => \$job_num,
			  "aa_sims=s"  => \$aa_sims,
			  "rna_sims=s"   => \$rna_sims,
			 );

unless (-s $aa_sims) {
    print  "input aa sims file: [$rna_sims] does not exist or is size zero\n";
    print_usage();
    exit __LINE__;
}

unless (-s $rna_sims) {
    print  "input rna sims file: [$rna_sims] does not exist or is size zero\n";
    print_usage();
    exit __LINE__;
}

my $run_dir = getcwd();

# memcache sims for aa - superblat results should always be sorted by query id then bit score
system("process_sims_by_source_mem $params --in_sim $aa_sims --out_filter $run_dir/$prefix_aa.sims.filter --out_expand $run_dir/$prefix_aa.expand.protein --out_ontology $run_dir/$prefix_aa.expand.ontology --out_lca $run_dir/$prefix_aa.expand.lca >> $run_dir/process_aa_sims.out 2>&1") == 0 or exit __LINE__;

# memcaches sims for rna
system("process_sims_by_source_mem $params --in_sim $rna_sims --out_filter $run_dir/$prefix_rna.sims.filter --out_rna $run_dir/$prefix_rna.expand.rna --out_lca $run_dir/$prefix_rna.expand.lca >> $run_dir/process_rna_sims.out 2>&1") == 0 or exit __LINE__;

print "Finished $stage_name on job $job_num\n";

exit(0);

sub print_usage{
    print "USAGE: awe_annotate.pl -aa_sims=<input aa sims file> -rna_sim=<input rna sims file>\n";
}
