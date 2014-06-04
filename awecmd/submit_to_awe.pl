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

use PipelineJob;
use PipelineAWE_Conf;

use DBI;
use JSON;
use Template;
use Getopt::Long;
use File::Basename;
use LWP::UserAgent;
use Data::Dumper;

# options
my $job_id    = "";
my $input     = "";
my $awe_url   = "";
my $shock_url = "";
my $template  = "";
my $no_start  = 0;
my $help      = 0;

my $options = GetOptions (
        "job_id=s"    => \$job_id,
        "input=s"     => \$input,
		"awe_url=s"   => \$awe_url,
		"shock_url=s" => \$shock_url,
		"template=s"  => \$template,
		"no_start!"   => \$no_start,
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

# set obj handles
my $jobdb = PipelineJob::get_jobcache_dbh(
    $PipelineAWE_Conf::job_dbhost,
    $PipelineAWE_Conf::job_dbname,
    $PipelineAWE_Conf::job_dbuser,
    $PipelineAWE_Conf::job_dbpass );
my $tpage = Template->new();
my $agent = LWP::UserAgent->new();
my $json  = JSON->new;
$json = $json->utf8();
$json->max_size(0);
$json->allow_nonref;

# get default urls
my $vars = $PipelineAWE_Conf::template_keywords;
if ($shock_url) {
    $vars->{shock_url} = $shock_url;
}
if (! $awe_url) {
    $awe_url = $PipelineAWE_Conf::awe_url;
}
if (! $template) {
    $template = $PipelineAWE_Conf::template_file;
}

# get job related info from DB
my $jobj = PipelineJob::get_jobcache_info($jobdb, $job_id);
unless ($jobj && (scalar(keys %$jobj) > 0) && exists($jobj->{options})) {
    print STDERR "ERROR: Job $job_id does not exist.\n";
    print STDERR get_usage();
    exit __LINE__;
}
my $jstat = PipelineJob::get_job_statistics($jobdb, $job_id);
my $jattr = PipelineJob::get_job_attributes($jobdb, $job_id);
my $jopts = {};
foreach my $opt (split(/\&/, $jobj->{options})) {
    my ($k, $v) = split(/=/, $opt);
    $jopts->{$k} = $v;
}

# build upload attributes
my $up_attr = {
    id          => 'mgm'.$jobj->{metagenome_id},
    job_id      => $job_id,
    name        => $jobj->{name},
    created     => $jobj->{created_on},
    status      => 'private',
    assembled   => $jattr->{assembled} ? 'yes' : 'no',
    data_type   => 'sequence',
    seq_format  => 'bp',
    file_format => ($jattr->{file_type} && ($jattr->{file_type} == 'fastq')) ? 'fastq' : 'fasta',
    stage_id    => '050',
    stage_name  => 'upload',
    type        => 'metagenome',
    statistics  => {},
    sequence_type    => $jobj->{sequence_type} || $jattr->{sequence_type_guess},
    pipeline_version => $vars->{pipeline_version}
};
if ($jobj->{project_id} && $jobj->{project_name}) {
    $up_attr->{project_id}   = 'mgp'.$jobj->{project_id};
    $up_attr->{project_name} = $jobj->{project_name};
}
foreach my $s (keys %$jstat) {
    if ($s =~ /(.+)_raw$/) {
        $up_attr->{statistics}{$1} = $jstat->{$s};
    }
}

# upload input to shock
$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;
my $content = {
    upload     => $input,
    attributes => [undef, "$input.json", Content => $json->encode($up_attr)];
};
my $spost = $agent->post(
    'http://'.$vars->{shock_url}.'/node',
    'Authorization', "OAuth $shock_pipeline_token",
    'Content_Type', 'multipart/form-data',
    'Content', $content
);
my $sres = $json->decode($spost->content);

# populate workflow variables
$vars->{job_id}         = $job_id;
$vars->{mg_id}          = $up_attr->{id};
$vars->{mg_name}        = $up_attr->{name};
$vars->{job_date}       = $up_attr->{created};
$vars->{seq_type}       = $up_attr->{sequence_type};
$vars->{project_id}     = $up_attr->{project_id} || '';
$vars->{project_name}   = $up_attr->{project_name} || '';
$vars->{user}           = 'mgu'.$jobj->{owner} || '';
$vars->{inputfile}      = basename($input);
$vars->{shock_node}     = $sres->{data}{id};
$vars->{filter_options} = $jopts->{filter_options} || 'skip';
$vars->{assembled}      = $jattr->{assembled} || 0;
$vars->{dereplicate}    = $jopts->{dereplicate} || 1;
$vars->{bowtie}         = $jopts->{bowtie} || 1;
$vars->{screen_indexes} = $jopts->{screen_indexes} || 'h_sapiens';

# set node output type for preprocessing
if ($up_attr->{file_format} eq 'fastq') {
    $vars->{preprocess_pass} = "";
    $vars->{preprocess_fail} = "";
} elsif ($vars->{filter_options} eq 'skip') {
    $vars->{preprocess_pass} = qq(,
                    "type": "copy",
                    "formoptions": {                        
                        "parent_node": ").$sres->{data}{id}.qq(",
                        "copy_indexes": "1"
                    });
    $vars->{preprocess_fail} = "";
} else {
    $vars->{preprocess_pass} = qq(,
                    "type": "subset",
                    "formoptions": {                        
                        "parent_node": ").$sres->{data}{id}.qq(",
                        "parent_index": "record"
                    });
    $vars->{preprocess_fail} = $vars->{preprocess_pass};
}
# set node output type for dereplication
if ($vars->{dereplicate} == 0) {
    $vars->{dereplicate_pass} = qq(,
                    "type": "copy",
                    "formoptions": {                        
                        "parent_name": "${job_id}.100.preprocess.passed.fna",
                        "copy_indexes": "1"
                    });
    $vars->{dereplicate_fail} = "";
} else {
    $vars->{dereplicate_pass} = qq(,
                    "type": "subset",
                    "formoptions": {                        
                        "parent_name": "${job_id}.100.preprocess.passed.fna",
                        "parent_index": "record"
                    });
    $vars->{dereplicate_fail} = $vars->{dereplicate_pass};
}
# set node output type for bowtie
if ($vars->{bowtie} == 0) {
    $vars->{bowtie_pass} = qq(,
                    "type": "copy",
                    "formoptions": {                        
                        "parent_name": "${job_id}.150.dereplication.passed.fna",
                        "copy_indexes": "1"
                    });
} else {
    $vars->{bowtie_pass} = qq(,
                    "type": "subset",
                    "formoptions": {                        
                        "parent_name": "${job_id}.150.dereplication.passed.fna",
                        "parent_index": "record"
                    });
}

# build bowtie index list
my $bowtie_url = $PipelineAWE_Conf::shock_bowtie_url || $vars->{shock_url};
$vars->{index_download_urls} = "";
foreach my $idx (split(/,/, $vars->{screen_indexes})) {
    if (exists $PipelineAWE_Conf::shock_bowtie_indexes->{$idx}) {
        while (my ($ifile, $inode) = each %{$PipelineAWE_Conf::shock_bowtie_indexes->{$idx}}) {
            $vars->{index_download_urls} .= qq(
                "$ifile": {
                    "url": "http://${bowtie_url}/node/${inode}?download"
                },);
        }
    }
}
if ($vars->{index_download_urls} eq "") {
    print STDERR "ERROR: No valid bowtie indexes found in ".$vars->{screen_indexes}."\n";
    print STDERR get_usage();
    exit __LINE__;
}
chop $vars->{index_download_urls};

# replace variables
my $workflow = $PipelineAWE_Conf::temp_dir/$job_num.".awe_workflow.json";
$tpage->process($template, $vars, $workflow) || die $tpage->error()."\n";

# test mode
if ($no_start) {
    print "workflow at: $workflow\n";
    exit 0;
}

# submit to AWE
my $apost = $agent->post(
    'http://'.$awe_url.'/job',
    'Datatoken', $shock_pipeline_token,
    'Content_Type', 'multipart/form-data',
    'Content', [ upload => [$workflow] ]
);
my $ares = $json->decode($apost->content);

# get info
my $awe_id  = $ares->{data}{id};
my $awe_job = $ares->{data}{jid};
my $state   = $ares->{data}{state};

# add to lookup table
my $tbl = $PipelineAWE_Conf::awe_mgrast_lookup_table;
my $dbh = DBI->connect(
    "DBI:mysql:".$PipelineAWE_Conf::awe_mgrast_lookup_db.";host=".$PipelineAWE_Conf::awe_mgrast_lookup_host,
    $PipelineAWE_Conf::awe_mgrast_lookup_user,
    $PipelineAWE_Conf::awe_mgrast_lookup_pass
    ) || die DBI->errstr."\n";
my $cmd = "INSERT INTO $tbl (job, awe_id, awe_url, status, submitted, last_update) VALUES ($job_id, '$awe_job', 'http://$awe_url/job/$awe_id', '$state', now(), now())";
my $sth = $dbh->prepare($str);
$sth->execute() || die $sth->errstr."\n";

sub get_usage {
    return "USAGE: submit_to_awe.pl -job_id=<job identifier> -input=<input file> [-awe_url=<awe url> -shock_url=<shock url> -template=<template file>]\n";
}

# enable hash-resolving in the JSON->encode function
sub TO_JSON { return { %{ shift() } }; }

