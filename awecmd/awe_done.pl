#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
umask 000;

# options
my $job_id  = "";
my $dbhost  = "";
my $dbname  = "";
my $dbuser  = "";
my $help    = 0;
my $options = GetOptions (
		"job=s"      => \$job_id,
		"dbhost=s"   => \$dbhost,
		"dbname=s"   => \$dbname,
		"dbuser=s"   => \$dbuser,
		"help!"      => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($job_id)==0){
    print STDERR "ERROR: A job ID is required.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (! ($dbhost && $dbname && $dbuser)){
    print STDERR "ERROR: Job DB info required.\n";
    print STDERR get_usage();
    exit __LINE__;
}

print "do stuff to finish up job $job\n";

## TODO - everything

exit(0);

sub get_usage {
    return "USAGE: awe_done.pl -job=<job identifier> -dbhost=<db host> -dbname=<db name> -dbuser=<db user>\n";
}
