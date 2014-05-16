#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
umask 000;

# options
my $job_id       = "";
my $nr_ver       = "";
my $ann_ver      = "";
my $upload_stat  = "";
my $qc_stat      = "";
my $post_qc_stat = "";
my $source_stat  = "";
my $genecall     = "";
my $rna_clust    = "";
my $rna_map      = "";
my $aa_clust     = "";
my $aa_map       = "";
my $help         = 0;
my $options      = GetOptions (
		"job=s"          => \$job_id,
		"nr_ver=s"       => \$nr_ver,
		"ann_ver=s"      => \$ann_ver,
		"ann_ver=s"      => \$ann_ver,
		"upload_stat=s"  => \$upload_stat,
		"qc_stat=s"      => \$qc_stat,
		"post_qc_stat=s" => \$post_qc_stat,
		"source_stat=s"  => \$source_stat,
		"genecall=s"     => \$genecall,
		"rna_clust=s"    => \$rna_clust,
		"rna_map=s"      => \$rna_map,
		"aa_clust=s"     => \$aa_clust,
		"aa_map=s"       => \$aa_map,
		"help!"          => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($job_id)==0){
    print STDERR "ERROR: A job ID is required.\n";
    print STDERR get_usage();
    exit __LINE__;
}

# get db variables from enviroment
my $jdbhost = $ENV{'JOB_DB_HOST'} || undef;
my $jdbname = $ENV{'JOB_DB_NAME'} || undef;
my $jdbuser = $ENV{'JOB_DB_USER'} || undef;
my $jdbpass = $ENV{'JOB_DB_PASS'} || undef;
my $adbhost = $ENV{'ANALYSIS_DB_HOST'} || undef;
my $adbname = $ENV{'ANALYSIS_DB_NAME'} || undef;
my $adbuser = $ENV{'ANALYSIS_DB_USER'} || undef;
my $adbpass = $ENV{'ANALYSIS_DB_PASS'} || undef;

unless ( defined($jdbhost) && defined($jdbname) && defined($jdbuser) && defined($jdbpass) &&
         defined($adbhost) && defined($adbname) && defined($adbuser) && defined($adbpass) ) {
    print STDERR "ERROR: missing analysis database ENV variables.\n";
    print STDERR get_usage();
    exit __LINE__;
}

print "do stuff to finish up job $job\n";
## TODO - everything

# create metagenome statistics node
my $mgstats = {};

# create metagenome metadata node

# compute sequence stats

# compute cluster stats

# update JobDB - stats and info



exit(0);

sub get_usage {
    return "USAGE: awe_done.pl -job=<job identifier>\n";
}
