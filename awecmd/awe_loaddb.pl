#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
umask 000;

# options
my %types = (
    md5      => "md5s",
    ontology => "ontologies",
    function => "functions",
    organism => "organisms",
    lca      => "lcas"
);
my $tbl_range = 5000;
my $job_id  = "";
my $input   = "";
my $psql    = "";
my $type    = "";
my $ver_db  = 1;
my $help    = 0;
my $options = GetOptions (
		"job=s"      => \$job_id,
		"input=s"    => \$input,
		"psql=s"     => \$psql,
		"type=s"     => \$type,
		"nr_ver=s"   => \$ver_db,
		"help!"      => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($input)==0){
    print STDERR "ERROR: An input file was not specified.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! -e $input){
    print STDERR "ERROR: The input summary file [$input] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! -e $psql){
    print STDERR "ERROR: The input postgresql file [$psql] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}elsif (length($job_id)==0){
    print STDERR "ERROR: A job ID is required.\n";
    print STDERR get_usage();
    exit 1;
}elsif (length($type)==0){
    print STDERR "ERROR: A summary type is required.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! exists($types{$type})){
    print STDERR "ERROR: type $type is invalid.\n";
    print STDERR get_usage();
    exit 1;
}

# get db variables from enviroment
my $dbhost = $ENV{'ANALYSIS_DB_HOST'} || undef;
my $dbname = $ENV{'ANALYSIS_DB_NAME'} || undef;
my $dbuser = $ENV{'ANALYSIS_DB_USER'} || undef;
my $dbpass = $ENV{'ANALYSIS_DB_PASS'} || undef;

unless (defined($dbhost) && defined($dbname) && defined($dbuser) && defined($dbpass)) {
    print STDERR "ERROR: missing analysis database ENV variables.\n";
    print STDERR get_usage();
    exit 1;
}

# place postgresql cert in home dir
PipelineAWE::run_cmd('tar -xf '.$psql.' -C '.$ENV{'HOME'}, 1);

# build / run command
my $dbopts  = "--dbhost ".$dbhost." --dbname ".$dbname." --dbuser ".$dbuser." --dbpass ".$dbpass." --dbtable_range ".$tbl_range;
my $fileopt = "--".$types{$type}."_filename ".$input;
PipelineAWE::run_cmd("load_summary2db --verbose --reload --seq-db-version $ver_db --job $job_id $dbopts $fileopt");

# cleanup
PipelineAWE::run_cmd('rm -rf '.$ENV{'HOME'}.'/.postgresql');

exit 0;

sub get_usage {
    return "USAGE: awe_loaddb.pl -job=<job identifier> -input=<input summary file> -psql=<postgresql cert tarball> -type=<summary types> -dbhost=<db host> -dbname=<db name> -dbuser=<db user> [-nr_ver=<nr db version>]\n";
}
