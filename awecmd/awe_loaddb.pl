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
    PipelineAWE::logger('error', "input file was not specified");
    exit 1;
}elsif (! -e $input){
    PipelineAWE::logger('error', "input summary file [$input] does not exist");
    exit 1;
}elsif (! -e $psql){
    PipelineAWE::logger('error', "input postgresql file [$psql] does not exist");
    exit 1;
}elsif (length($job_id)==0){
    PipelineAWE::logger('error', "job ID is required");
    exit 1;
}elsif (length($type)==0){
    PipelineAWE::logger('error', "summary type is required");
    exit 1;
}elsif (! exists($types{$type})){
    PipelineAWE::logger('error', "type $type is invalid");
    exit 1;
}

# get db variables from enviroment
my $dbhost = $ENV{'ANALYSIS_DB_HOST'} || undef;
my $dbname = $ENV{'ANALYSIS_DB_NAME'} || undef;
my $dbuser = $ENV{'ANALYSIS_DB_USER'} || undef;
my $dbpass = $ENV{'ANALYSIS_DB_PASS'} || undef;

unless (defined($dbhost) && defined($dbname) && defined($dbuser) && defined($dbpass)) {
    PipelineAWE::logger('error', "missing analysis database ENV variables");
    exit 1;
}

# place postgresql cert in home dir
PipelineAWE::run_cmd('tar -xf '.$psql.' -C '.$ENV{'HOME'}, 1);
PipelineAWE::run_cmd('chown -R '.$ENV{'USERNAME'}.':'.$ENV{'USERNAME'}.' '.$ENV{'HOME'}.'/.postgresql', 1);
my $pgssldir  = $ENV{'HOME'}.'/.postgresql';
my $pgsslcert = "sslcert=".$pgssldir."/postgresql.crt;sslkey=".$pgssldir."/postgresql.key";

# build / run command
my $dbopts  = "--dbcert ".$pgsslcert." --dbhost ".$dbhost." --dbname ".$dbname." --dbuser ".$dbuser." --dbpass ".$dbpass." --dbtable_range ".$tbl_range;
my $fileopt = "--".$types{$type}."_filename ".$input;
PipelineAWE::run_cmd("load_summary2db --verbose --reload --seq-db-version $ver_db --job $job_id $dbopts $fileopt");

# cleanup
PipelineAWE::run_cmd('rm -rf '.$pgssldir);

exit 0;

sub get_usage {
    return "USAGE: awe_loaddb.pl -job=<job identifier> -input=<input summary file> -psql=<postgresql cert tarball> -type=<summary types> -dbhost=<db host> -dbname=<db name> -dbuser=<db user> [-nr_ver=<nr db version>]\n";
}
