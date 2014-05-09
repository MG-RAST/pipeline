#!/usr/bin/env perl

# MG-RAST pipeline job submitter for AWE
# Command name: submit_to_awe
# Use case: submit a job with a local input file and a pipeline template,
#           input file is local and will be uploaded to shock automatially.
# Operations:
#      1. upload input file to shock
#      2. create job script based on job template and available info
#      3. submit the job json script to awe

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use PipelineAWE_Conf;

use DBI;
use JSON;
use Template;
use Getopt::Long;
use LWP::UserAgent;
use Data::Dumper;

# options
my $job_id    = "";
my $input     = "";
my $awe_url   = "";
my $shock_url = "";
my $template  = "";
my $help      = 0;

my $options = GetOptions (
        "job_id=s"    => \$job_id,
        "input=s"     => \$input,
		"awe_url=s"   => \$awe_url,
		"shock_url=s" => \$shock_url,
		"template=s"  => \$template,
		"help!"       => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($job_id)==0){
    print STDERR "ERROR: A job identifier is required.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (length($input)==0){
    print STDERR "ERROR: An input file was not specified.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (! -e $input){
    print STDERR "ERROR: The input file [$input] does not exist.\n";
    print STDERR get_usage();
    exit __LINE__;
}

# replacement variables
my $vars = $PipelineAWE_Conf::template_keywords;
# replace optional
if ($shock_url) {
    $vars->{shock_url} = $shock_url
}

# get job related info from DB
my $jobj = PipelineAWE::get_jobcache_info($job_id);
unless ($jobj && (scalar(keys %$jobj) > 0) && exists($jobj->{options})) {
    print STDERR "ERROR: A job identifier does not exist.\n";
    print STDERR get_usage();
    exit __LINE__;
}
my $jattr = PipelineAWE::get_job_attributes($job_id);
my $jopts = {};
foreach my $opt (split(/\&/, $jobj->{options})) {
    my ($k, $v) = split(/=/, $opt);
    $jopts->{$k} = $v;
}

# populate variables
$vars->{job_id}         = $job_id;
$vars->{mg_id}          = 'mgm'.$jobj->{metagenome_id};
$vars->{mg_name}        = $jobj->{name};
$vars->{job_date}       = $jobj->{created_on};
$vars->{project_id}     = 'mgp'.$jobj->{project_id} || '';
$vars->{project_name}   = $jobj->{project_name} || '';
$vars->{user}           = 'mgu'.$jobj->{owner} || '';
$vars->{filter_options} = $jopts->{filter_options} || 'skip';
$vars->{assembled}      = $jattr->{assembled} || 0;


sub get_usage {
    return "USAGE: submit_to_awe.pl -job_id=<job identifier> -input=<input file> [-awe_url=<awe url> -shock_url=<shock url> -template=<template file>]\n";
}
