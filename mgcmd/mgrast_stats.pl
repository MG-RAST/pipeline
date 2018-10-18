#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;

use POSIX qw/strftime/;
use Scalar::Util qw(looks_like_number);
use List::Util qw(max min sum);
use URI::Escape;
use Getopt::Long;
umask 000;

# options
my $job_id    = "";
my $nr_ver    = "";
my $ann_ver   = "";
my $api_url   = "";
my $upload    = "";
my $qc        = "";
my $adtrim    = "";
my $preproc   = "";
my $derep     = "";
my $post_qc   = "";
my $source    = "";
my $search    = "";
my $rna_clust = "";
my $rna_map   = "";
my $genecall  = "";
my $aa_clust  = "";
my $aa_map    = "";
my $ontol     = "";
my $filter    = "";
my $md5_abund = "";
my $dark      = "";
my $m5nr_db   = "";
my $taxa_hier = "";
my $ont_hier  = "";
my $help      = 0;
my $options   = GetOptions (
		"job=s"       => \$job_id,
		"nr_ver=s"    => \$nr_ver,
		"ann_ver=s"   => \$ann_ver,
		"api_url=s"   => \$api_url,
		"upload=s"    => \$upload,
		"qc=s"        => \$qc,
        "adtrim=s"    => \$adtrim,
		"preproc=s"   => \$preproc,
		"derep=s"     => \$derep,
		"post_qc=s"   => \$post_qc,
		"source=s"    => \$source,
		"search=s"    => \$search,
		"rna_clust=s" => \$rna_clust,
		"rna_map=s"   => \$rna_map,
		"genecall=s"  => \$genecall,
		"aa_clust=s"  => \$aa_clust,
		"aa_map=s"    => \$aa_map,
        "ontol=s"     => \$ontol,
		"filter=s"    => \$filter,
		"md5_abund=s" => \$md5_abund,
        "dark=s"      => \$dark,
		"m5nr_db=s"   => \$m5nr_db,
		"taxa_hier=s" => \$taxa_hier,
		"ont_hier=s"  => \$ont_hier,
		"help!"       => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($job_id)==0){
    PipelineAWE::logger('error', "job ID is required");
    exit 1;
}

unless ($api_url) {
    $api_url = $PipelineAWE::default_api;
}

# get api variable
my $api_key = $ENV{'MGRAST_WEBKEY'} || undef;

### update attribute stats
my $done_attr = PipelineAWE::get_userattr();
my $mgid = $done_attr->{id};

# get attributes
PipelineAWE::logger('info', "Computing file statistics and updating attributes");
my $pq_attr = PipelineAWE::read_json($post_qc.'.json');
my $sr_attr = PipelineAWE::read_json($search.'.json');
my $gc_attr = PipelineAWE::read_json($genecall.'.json');
my $rc_attr = PipelineAWE::read_json($rna_clust.'.json');
my $ac_attr = PipelineAWE::read_json($aa_clust.'.json');
my $rm_attr = PipelineAWE::read_json($rna_map.'.json');
my $am_attr = PipelineAWE::read_json($aa_map.'.json');
# add statistics
$pq_attr->{statistics} = PipelineAWE::get_seq_stats($post_qc, 'fasta', undef, "$post_qc.stats");
$sr_attr->{statistics} = PipelineAWE::get_seq_stats($search, 'fasta');
$gc_attr->{statistics} = PipelineAWE::get_seq_stats($genecall, 'fasta', 1);
$rc_attr->{statistics} = PipelineAWE::get_seq_stats($rna_clust, 'fasta');
$ac_attr->{statistics} = PipelineAWE::get_seq_stats($aa_clust, 'fasta', 1);
$rm_attr->{statistics} = PipelineAWE::get_cluster_stats($rna_map);
$am_attr->{statistics} = PipelineAWE::get_cluster_stats($aa_map);
# print attributes
PipelineAWE::print_json($post_qc.'.json', $pq_attr);
PipelineAWE::print_json($search.'.json', $sr_attr);
PipelineAWE::print_json($genecall.'.json', $gc_attr);
PipelineAWE::print_json($rna_clust.'.json', $rc_attr);
PipelineAWE::print_json($aa_clust.'.json', $ac_attr);
PipelineAWE::print_json($rna_map.'.json', $rm_attr);
PipelineAWE::print_json($aa_map.'.json', $am_attr);
# cleanup
unlink($post_qc, $search, $genecall, $rna_clust, $aa_clust, $rna_map, $aa_map);

# optional adapter trim file
if ($adtrim) {
    my $at_attr = PipelineAWE::read_json($adtrim.'.json');
    $at_attr->{statistics} = PipelineAWE::get_seq_stats($adtrim, $at_attr->{file_format});
    PipelineAWE::print_json($adtrim.'.json', $at_attr);
    unlink($adtrim);
}
# optional darkmatter file
if ($dark) {
    my $dm_attr = PipelineAWE::read_json($dark.'.json');
    $dm_attr->{statistics} = PipelineAWE::get_seq_stats($dark, 'fasta', 1);
    PipelineAWE::print_json($dark.'.json', $dm_attr);
    unlink($dark);
}

### JobDB update
# get JobDB statistics
PipelineAWE::logger('info', "Retrieving sequence statistics from attributes");
my $job_stats = PipelineAWE::obj_from_url($api_url."/job/statistics/".$mgid, $api_key)->{data};
# get additional attributes
my $up_attr = PipelineAWE::read_json($upload.'.json');
my $qc_attr = PipelineAWE::read_json($qc.'.json');
my $de_attr = PipelineAWE::read_json($derep.'.json');
my $pp_attr = PipelineAWE::read_json($preproc.'.json');
my $fl_attr = PipelineAWE::read_json($filter.'.json');

# populate job_stats
$job_stats->{sequence_count_dereplication_removed} = $de_attr->{statistics}{sequence_count} || '0';  # derep fail
$job_stats->{read_count_processed_rna} = $sr_attr->{statistics}{sequence_count} || '0';      # pre-cluster / rna search
$job_stats->{read_count_processed_aa}  = $gc_attr->{statistics}{sequence_count} || '0';      # pre-cluster / genecall
$job_stats->{sequence_count_processed_rna} = $rc_attr->{statistics}{sequence_count} || '0';  # post-cluster / rna clust
$job_stats->{sequence_count_processed_aa}  = $ac_attr->{statistics}{sequence_count} || '0';  # post-cluster / aa clust

if ($up_attr->{statistics}) {
    map { $job_stats->{$_.'_raw'} = $up_attr->{statistics}{$_} } keys %{$up_attr->{statistics}}; # raw seq stats
}
if ($qc_attr->{statistics}) {
    map { $job_stats->{$_} = $qc_attr->{statistics}{$_} } keys %{$qc_attr->{statistics}};        # qc stats
}
map { $job_stats->{$_} = $fl_attr->{statistics}{$_} } keys %{$fl_attr->{statistics}};        # sims filter stats
map { $job_stats->{$_.'_preprocessed_rna'} = $pp_attr->{statistics}{$_} } keys %{$pp_attr->{statistics}};  # preprocess seq stats
map { $job_stats->{$_.'_preprocessed'}     = $pq_attr->{statistics}{$_} } keys %{$pq_attr->{statistics}};  # screen seq stats
map { $job_stats->{$_.'_processed_rna'}    = $rm_attr->{statistics}{$_} } keys %{$rm_attr->{statistics}};  # rna clust stats
map { $job_stats->{$_.'_processed_aa'}     = $am_attr->{statistics}{$_} } keys %{$am_attr->{statistics}};  # aa clust stats

# read ratios
my ($aa_ratio, $rna_ratio) = read_ratios($job_stats);
$job_stats->{ratio_reads_aa} = $aa_ratio;
$job_stats->{ratio_reads_rna} = $rna_ratio;

# get sequence type
my $job_attrs = PipelineAWE::obj_from_url($api_url."/job/attributes/".$mgid, $api_key)->{data};
my $seq_type  = seq_type($job_attrs, $rna_ratio);

# get versions
my $versions = {
    pipeline_version => $done_attr->{pipeline_version},
    m5rna_sims_version => $nr_ver,
    m5nr_sims_version  => $nr_ver,
    m5rna_annotation_version => $ann_ver,
    m5nr_annotation_version  => $ann_ver
};

# compute abundances from md5 file and m5nr
my $func_abund_obj  = []; # for stats and solr
my $taxa_abund_obj  = {}; # for stats and solr
my $ont_abund_obj   = {}; # for stats only
my $md5_list_obj    = []; # for solr only
my $func_abund_file = $md5_abund.".function";
my $taxa_abund_file = $md5_abund.".taxonomy";
my $ont_abund_file  = $md5_abund.".ontology";
my $md5_list_file   = $md5_abund.".md5";

PipelineAWE::logger('info', "Building / computing annotation abundance profiles");
PipelineAWE::run_cmd("md5_to_annotation.py -d $m5nr_db --tax_map $taxa_hier --ont_map $ont_hier -i $md5_abund -f $func_abund_file -t $taxa_abund_file -o $ont_abund_file -m md5_list_file");
eval {
    $func_abund_obj = PipelineAWE::read_json($func_abund_file);
    $taxa_abund_obj = PipelineAWE::read_json($taxa_abund_file);
    $ont_abund_obj  = PipelineAWE::read_json($ont_abund_file);
    $md5_list_obj   = PipelineAWE::read_json($md5_list_file);
};
if ($@) {
    logger('error', 'unable to compute annotation abundances, output is invalid json');
    logger('debug', 'md5_to_annotation.py: '.$@);
    exit 1;
}
# minimal test for missing data
if (scalar(@{$taxa_abund_obj->{domain}}) == 0) {
    PipelineAWE::logger('error', "unable to compute annotation abundances, data is missing from DB.");
    exit 1;
}

# diversity computation
PipelineAWE::logger('info', "Computing alpha diversity and species rarefaction");
my @species_abund = map {$_->[1]} @{$taxa_abund_obj->{species}};
my $rarefaction   = get_rarefaction_xy(\@species_abund, $job_stats->{sequence_count_raw});
$job_stats->{alpha_diversity_shannon} = get_alpha_diversity(\@species_abund);

if ($job_stats->{alpha_diversity_shannon} == 0) {
    PipelineAWE::logger('error', "unable to compute alpha diversity, organism abundance data is missing");
    exit 1;
}

# update DB
PipelineAWE::logger('info', "Updating Job DB with new stats / info");
PipelineAWE::post_data($api_url."/job/statistics", $api_key, {metagenome_id => $mgid, statistics => $job_stats});
PipelineAWE::post_data($api_url."/job/attributes", $api_key, {metagenome_id => $mgid, attributes => $versions});
PipelineAWE::obj_from_url($api_url."/metagenome/$mgid/changesequencetype/$seq_type", $api_key);

### create metagenome statistics node
# get stats from inputs
PipelineAWE::logger('info', "Building metagenome statistics file");
my $u_stats = PipelineAWE::read_json($upload);
my $q_stats = PipelineAWE::read_json($qc);
my $s_stats = PipelineAWE::read_json($source);

# get qc stats - input stats may be from done stage if this is a rerun job
my $up_gc_hist  = undef;
my $up_len_hist = undef;
my $qc_all_stat = undef;
if ($q_stats->{sequence_stats}) {
    # $q_stats is from previous mg stats file
    $up_gc_hist  = $q_stats->{gc_histogram}{upload};
    $up_len_hist = $q_stats->{length_histogram}{upload};
    $qc_all_stat = $q_stats->{qc};
} else {
    # $q_stats is from previous QC stat stages
    $up_gc_hist  = $u_stats->{gc_histogram};
    $up_len_hist = $u_stats->{length_histogram};
    $qc_all_stat = $q_stats;
}

# build stats obj
my $mgstats = {
    gc_histogram => {
        upload  => $up_gc_hist,
        post_qc => PipelineAWE::file_to_array("$post_qc.stats.gcs")
    },
    length_histogram => {
        upload  => $up_len_hist,
        post_qc => PipelineAWE::file_to_array("$post_qc.stats.lens")
    },
    qc => $qc_all_stat,
    source => $s_stats,
    taxonomy => $taxa_abund_obj,
    function => $func_abund_obj,
    ontology => $ont_abund_obj,
    rarefaction => $rarefaction,
    sequence_stats => $job_stats
};

# output stats object
PipelineAWE::logger('info', "Outputing statistics file");
PipelineAWE::print_json($job_id.".statistics.json", $mgstats);
PipelineAWE::create_attr($job_id.".statistics.json.attr", undef, {data_type => "statistics", file_format => "json"});

####### depricated, now use elasticsearch
# upload of solr data
#PipelineAWE::logger('info', "POSTing solr data");
#my $solrdata = {
#    sequence_stats => $mgstats->{sequence_stats},
#    function => [ map {$_->[0]} @$func_abund_obj ],
#    organism => [ map {$_->[0]} @{$taxa_abund_obj->{species}} ],
#    md5 => $md5_list_obj
#};
#PipelineAWE::post_data($api_url."/job/solr", $api_key, {metagenome_id => $mgid, solr_data => $solrdata});

# set database to complete before ES load
my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
PipelineAWE::post_data($api_url."/job/attributes", $api_key, {metagenome_id => $mgid, attributes => {completedtime => $now}});
PipelineAWE::post_data($api_url."/job/viewable", $api_key, {metagenome_id => $mgid, viewable => 1});

# just POST ES metadata for old DB
PipelineAWE::logger('info', "add metadata to ES");
my $esdata1 = {
    type => 'metadata',
    index => 'metagenome_index'
};
PipelineAWE::post_data($api_url."/search/$mgid", $api_key, $esdata1);

# POST ES data to new DB
PipelineAWE::logger('info', "POSTing ES data");
my $esdata2 = {
    type => 'all',
    index => 'metagenome_index_20180705',
    taxonomy => $taxa_abund_obj,
    function => $func_abund_obj
};
PipelineAWE::post_data($api_url."/search/$mgid", $api_key, $esdata2);

exit 0;

sub get_usage {
    return "USAGE: mgrast_stats.pl -job=<job identifier>\n";
}

sub read_ratios {
    # calculate ratio identified reads
    my ($stat_set) = @_;
    my $qc_aa_seqs    = exists($stat_set->{sequence_count_preprocessed}) ? $stat_set->{sequence_count_preprocessed} : 0;
    my $aa_sims       = exists($stat_set->{sequence_count_sims_aa}) ? $stat_set->{sequence_count_sims_aa} : 0;
    my $aa_clusts     = exists($stat_set->{cluster_count_processed_aa}) ? $stat_set->{cluster_count_processed_aa} : 0;
    my $aa_clust_seq  = exists($stat_set->{clustered_sequence_count_processed_aa}) ? $stat_set->{clustered_sequence_count_processed_aa} : 0;
    my $qc_rna_seqs   = exists($stat_set->{sequence_count_preprocessed_rna}) ? $stat_set->{sequence_count_preprocessed_rna} : 0;
    my $rna_sims      = exists($stat_set->{sequence_count_sims_rna}) ? $stat_set->{sequence_count_sims_rna} : 0;
    my $rna_clusts    = exists($stat_set->{cluster_count_processed_rna}) ? $stat_set->{cluster_count_processed_rna} : 0;
    my $rna_clust_seq = exists($stat_set->{clustered_sequence_count_processed_rna}) ? $stat_set->{clustered_sequence_count_processed_rna} : 0;
    my $aa_ratio      = $qc_aa_seqs ? ($aa_sims - $aa_clusts + $aa_clust_seq) / $qc_aa_seqs : 0;
    my $rna_ratio     = $qc_rna_seqs ? ($rna_sims - $rna_clusts + $rna_clust_seq) / $qc_rna_seqs : 0;
    return (sprintf("%.3f", $aa_ratio), sprintf("%.3f", $rna_ratio));
}

sub seq_type {
    my ($data_set, $rna_ratio) = @_;
    # trust amplicon
    my $seq_guess = exists($data_set->{sequence_type_guess}) ? $data_set->{sequence_type_guess} : '';
    if ($seq_guess eq 'Amplicon') {
        return 'Amplicon';
    }
    # use ratio for WGS or MT
    else {
        return ($rna_ratio > 0.25) ? 'MT' : 'WGS';
    }
}

sub get_alpha_diversity {
    my ($values) = @_;
    my $alpha = 0;
    my $h1    = 0;
    my $sum   = sum @$values;
    unless ($sum) {
        return $alpha;
    }
    foreach my $num (@$values) {
        my $p = $num / $sum;
        if ($p > 0) { $h1 += ($p * log(1/$p)) / log(2); }
    }
    $alpha = 2 ** $h1;
    return $alpha;
}

sub get_rarefaction_xy {
    my ($values, $nseq) = @_;
    my $rare = [];
    my $size = ($nseq > 1000) ? int($nseq / 1000) : 1;
    my @nums = sort {$a <=> $b} @$values;
    my $k    = scalar @nums;
    for (my $n = 0; $n < $nseq; $n += $size) {
        my $coeff = nCr2ln($nseq, $n);
        my $curr  = 0;
        map { $curr += exp( nCr2ln($nseq - $_, $n) - $coeff ) } @nums;
        push @$rare, [ $n, $k - $curr ];
    }
    return $rare;
}

# log of N choose R 
sub nCr2ln {
    my ($n, $r) = @_;
    my $c = 1;
    if ($r > $n) {
        return $c;
    }
    if (($r < 50) && ($n < 50)) {
        map { $c = ($c * ($n - $_)) / ($_ + 1) } (0..($r-1));
        return log($c);
    }
    if ($r <= $n) {
        $c = gammaln($n + 1) - gammaln($r + 1) - gammaln($n - $r); 
    } else {
        $c = -1000;
    }
    return $c;
}

# This is Stirling's formula for gammaln, used for calculating nCr
sub gammaln {
    my ($x) = @_;
    unless ($x > 0) { return 0; }
    my $s = log($x);
    return log(2 * 3.14159265458) / 2 + $x * $s + $s / 2 - $x;
}
