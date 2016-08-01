#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;

use POSIX qw/strftime/;
use Data::Dumper;
use Getopt::Long;
umask 000;

# options
my $job_id    = "";
my $stat_file = "";
my $source    = "";
my $ann_ver   = "";
my $api_url   = "";
my $help      = 0;
my $options   = GetOptions (
		"job=s"     => \$job_id,
		"stats=s"   => \$stat_file,
		"source=s"  => \$source,
		"ann_ver=s" => \$ann_ver,
		"api_url=s" => \$api_url,
		"help!"     => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($job_id)==0){
    print STDERR "ERROR: A job ID is required.\n";
    print STDERR get_usage();
    exit 1;
}

# get api variable
my $api_key = $ENV{'MGRAST_WEBKEY'} || undef;

### update attribute stats
my $done_attr = PipelineAWE::get_userattr();
my $mgid = $done_attr->{id};

# get old stats
my $mgstats = PipelineAWE::read_json($stat_file);
my $seq_num = $mgstats->{sequence_stats}{sequence_count_raw};

# get source stats
if ($source) {
    my $s_stats = PipelineAWE::read_json($source);
    my %s_map   = map { $_->{source_id}, $_->{source} } @{PipelineAWE::obj_from_url($api_url."/m5nr/sources?version=".$ann_ver)->{data}};
    my %s_data  = map { $s_map{$_}, $s_stats->{$_} } keys %$s_stats;
    $mgstats->{source} = \%s_data;
}

# get abundance stats from API, this is an asynchronous call
my $t1 = time;
my $get_abund = PipelineAWE::obj_from_url($api_url."/job/abundance/".$mgid."?type=all&ann_ver=".$ann_ver, $api_key);
while ($get_abund->{status} ne 'done') {
    sleep 30;
    $get_abund = PipelineAWE::obj_from_url($get_abund->{url}, $api_key);
}
my $abundances = $get_abund->{data};
print STDERR "compute abundance time: ".(time - $t1)."\n";

# diversity computation from API, this is an asynchronous call
my $t2 = time;
my $get_diversity = PipelineAWE::obj_from_url($api_url."/compute/rarefaction/".$mgid."?asynchronous=1&alpha=1&level=species&ann_ver=".$ann_ver."&seq_num=".$seq_num, $api_key);
while ($get_diversity->{status} ne 'done') {
    sleep 30;
    $get_diversity = PipelineAWE::obj_from_url($get_diversity->{url}, $api_key);
}
my $alpha_rare = $get_diversity->{data};
print STDERR "compute alpha_rare time: ".(time - $t2)."\n";

# new stats
$mgstats->{taxonomy} = $abundances->{taxonomy};
$mgstats->{function} = $abundances->{function};
$mgstats->{ontology} = $abundances->{ontology};
$mgstats->{rarefaction} = $alpha_rare->{rarefaction};
$mgstats->{sequence_stats}{alpha_diversity_shannon} = $alpha_rare->{alphadiversity};

PipelineAWE::obj_from_url($api_url."/job/statistics", $api_key, {metagenome_id => $mgid, statistics => {alpha_diversity_shannon => $alpha_rare->{alphadiversity}}});

# output stats object
print "Outputing statistics file\n";
PipelineAWE::print_json($job_id.".statistics.json", $mgstats);
PipelineAWE::create_attr($job_id.".statistics.json.attr", undef, {data_type => "statistics", file_format => "json"});

# upload of solr data
print "POSTing solr data\n";
my $solrdata = {
    sequence_stats => $mgstats->{sequence_stats},
    function => [ map {$_->[0]} @{$mgstats->{function}} ],
    organism => [ map {$_->[0]} @{$mgstats->{taxonomy}{species}} ]
};
PipelineAWE::obj_from_url($api_url."/job/solr", $api_key, {metagenome_id => $mgid, solr_data => $solrdata});

# done done !!
my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
PipelineAWE::obj_from_url($api_url."/job/attributes", $api_key, {metagenome_id => $mgid, attributes => {completedtime => $now}});
PipelineAWE::obj_from_url($api_url."/job/viewable", $api_key, {metagenome_id => $mgid, viewable => 1});

sub get_usage {
    return "USAGE: awe_done.pl -job=<job identifier> -stats=<old stats file> -source=<source abundance file> -ann_ver=<m5nr annotation version>\n";
}
