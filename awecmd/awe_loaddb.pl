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
my $input   = "";
my $job_id  = "";
my $dbhost  = "";
my $dbname  = "";
my $dbuser  = "";
my $type    = "";
my $ver_db  = 1;
my $help    = 0;
my $options = GetOptions (
		"input=s"    => \$input,
		"job=s"      => \$job_id,
		"dbhost=s"   => \$dbhost,
		"dbname=s"   => \$dbname,
		"dbuser=s"   => \$dbuser,
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
    exit __LINE__;
}elsif (! -e $input){
    print STDERR "ERROR: The input summary file [$input] does not exist.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (length($job_id)==0){
    print STDERR "ERROR: A job ID is required.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (! ($dbhost && $dbname && $dbuser)){
    print STDERR "ERROR: Analysis DB info required.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (length($type)==0){
    print STDERR "ERROR: A summary type is required.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (! exists($types{$type})){
    print STDERR "ERROR: type $type is invalid.\n";
    print STDERR get_usage();
    exit __LINE__;
}

my $dbopts  = "--dbhost ".$dbhost." --dbname ".$dbname." --dbuser ".$dbuser." --dbtable_range ".$tbl_range;
my $fileopt = "--".$types{$type}."_filename ".$input;
PipelineAWE::run_cmd("load_summary2db --verbose --reload --seq-db-version $ver_db --job $job_id $dbopts $fileopt");

exit(0);

sub get_usage {
    return "USAGE: awe_loaddb.pl -input=<input summary file> -job=<job identifier> -type=<summary types> -dbhost=<db host> -dbname=<db name> -dbuser=<db user> [-nr_ver=<nr db version>]\n";
}
