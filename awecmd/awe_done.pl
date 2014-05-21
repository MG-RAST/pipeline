#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use PipelineJob;
use PipelineAnalysis;

use LWP::UserAgent;
use HTTP::Request::StreamingUpload;
use Getopt::Long;
umask 000;

# options
my $job_id    = "";
my $nr_ver    = "";
my $ann_ver   = "";
my $upload    = "";
my $qc        = "";
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
my $help      = 0;
my $options   = GetOptions (
		"job=s"       => \$job_id,
		"nr_ver=s"    => \$nr_ver,
		"ann_ver=s"   => \$ann_ver,
		"upload=s"    => \$upload,
		"qc=s"        => \$qc,
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
		"help!"       => \$help
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

# get solr variables
my $solr_url = $ENV{'SOLR_SERVER'} || undef;
my $solr_col = $ENV{'SOLR_COLLECTION'} || undef;
unless ( defined($solr_url) && defined($solr_col) ) {
    print STDERR "ERROR: missing solr server ENV variable.\n";
    print STDERR get_usage();
    exit __LINE__;
}

# get db handles
my $jdbh = PipelineJob::get_jobcache_dbh($jdbhost, $jdbname, $jdbuser, $jdbpass);
my $adbh = PipelineAnalysis::get_analysis_dbh($adbhost, $adbname, $adbuser, $adbpass);

print "do stuff to finish up job $job\n";

### update attribute stats
# get attributes
my $gc_attr = PipelineAWE::read_json($genecall.'.json');
my $rc_attr = PipelineAWE::read_json($rna_clust.'.json');
my $ac_attr = PipelineAWE::read_json($aa_clust.'.json');
my $rm_attr = PipelineAWE::read_json($rna_map.'.json');
my $am_attr = PipelineAWE::read_json($aa_map.'.json');
# add statistics
$gc_attr->{statistics} = PipelineAWE::get_seq_stats($genecall, 'fasta', 1);
$rc_attr->{statistics} = PipelineAWE::get_seq_stats($rna_clust, 'fasta');
$ac_attr->{statistics} = PipelineAWE::get_seq_stats($aa_clust, 'fasta', 1);
$rm_attr->{statistics} = PipelineAWE::get_cluster_stats($rna_map);
$am_attr->{statistics} = PipelineAWE::get_cluster_stats($aa_map);
# print attributes
PipelineAWE::print_json($genecall.'.json', $gc_attr);
PipelineAWE::print_json($rna_clust.'.json', $rc_attr);
PipelineAWE::print_json($aa_clust.'.json', $ac_attr);
PipelineAWE::print_json($rna_map.'.json', $rm_attr);
PipelineAWE::print_json($aa_map.'.json', $am_attr);
# cleanup
unlink($genecall, $rna_clust, $aa_clust, $rna_map, $aa_map);

# get additional attributes
my $raw     = PipelineAWE::read_json($upload.'.json');
my $qc_attr = PipelineAWE::read_json($qc.'.json');
my $derep   = PipelineAWE::read_json($derep.'.json');
my $pre_rna = PipelineAWE::read_json($preproc.'.json');
my $pre_aa  = PipelineAWE::read_json($post_qc.'.json');
my $srch    = PipelineAWE::read_json($search.'.json');
my $sims    = PipelineAWE::read_json($filter.'.json');
my $annot   = PipelineAWE::read_json($ontol.'.json');

### JobDB update
# get JobDB statistics
my $job_stats = PipelineJob::get_job_statistics($jdbh, $job_id);
$job_stats->{alpha_diversity_shannon}  = PipelineAnalysis::get_alpha_diversity($dbh, $job, $ver);
$job_stats->{read_count_processed_rna} = $srch->{statistics}{sequence_count} || '0';    # pre-cluster
$job_stats->{read_count_processed_aa}  = $gc_attr->{statistics}{sequence_count} || '0'; # pre-cluster
$job_stats->{sequence_count_processed_rna} = $rc_attr->{statistics}{sequence_count} || '0';  # post-cluster
$job_stats->{sequence_count_processed_aa}  = $ac_attr->{statistics}{sequence_count} || '0';  # post-cluster
$job_stats->{sequence_count_dereplication_removed} = $derep->{statistics}{sequence_count} || '0';  # derep fail
map { $job_stats->{$_} = $qc_attr->{statistics}{$_} } keys %{$qc_attr->{statistics}};  # qc stats
map { $job_stats->{$_} = $sims->{statistics}{$_} } keys %{$sims->{statistics}};        # sims stats
map { $job_stats->{$_} = $annot->{statistics}{$_} } keys %{$annot->{statistics}};      # annotate stats
map { $job_stats->{$_} = $raw->{statistics}{$_}.'_raw' } keys %{$raw->{statistics}};   # raw seq stats
map { $job_stats->{$_} = $pre_rna->{statistics}{$_}.'_preprocessed_rna' } keys %{$pre_rna->{statistics}};  # preprocess seq stats
map { $job_stats->{$_} = $pre_aa->{statistics}{$_}.'_preprocessed' } keys %{$pre_aa->{statistics}};        # screen seq stats
map { $job_stats->{$_} = $rm_attr->{statistics}{$_}.'_processed_rna' } keys %{$rm_attr->{statistics}};     # rna clust stats
map { $job_stats->{$_} = $am_attr->{statistics}{$_}.'_processed_aa' } keys %{$am_attr->{statistics}};      # aa clust stats
# read ratios
my ($aa_ratio, $rna_ratio) = read_ratios($job_stats);
$job_stats->{ratio_reads_aa} = $aa_ratio;
$job_stats->{ratio_reads_rna} = $rna_ratio;

# get JobDB attributes
my $job_attrs = PipelineJob::get_job_statistics($jdbh, $job_id);
my $seq_type  = seq_type($job_attrs, $rna_ratio);

# update DB
PipelineJob::set_job_statistics($jdbh, $job_id, $job_stats);
PipelineJob::set_job_statistics($jdbh, $job_id, {sequence_type => $seq_type});

### create metagenome statistics node
# get stats from inputs
my $u_stats = PipelineAWE::read_json($upload);
my $q_stats = PipelineAWE::read_json($qc);
my $p_stats = PipelineAWE::read_json($post_qc);
my $s_stats = PipelineAWE::read_json($source);
my $s_map   = PipelineAnalysis::get_sources($adbh);
my %s_data  = map { $s_map->{$_}, $s_stats->{$_} } keys %$s_stats;
# get stats from DB
my $taxa = {};
foreach my $t (('domain', 'phylum', 'class', 'order', 'family', 'genus', 'species')) {
   my $other = ($t eq 'domain') ? 1 : 0;
   $taxa->{$t} = PipelineAnalysis::get_taxa_abundances($adbh, $job_id, $t, $other, $ann_ver);
}
# build stats obj
my $mgstats = {
    gc_histogram => {
        upload  => $u_stats->{gc_histogram},
        post_qc => $p_stats->{gc_histogram}
    },
    length_histogram => {
        upload  => $u_stats->{length_histogram},
        post_qc => $p_stats->{length_histogram}
    },
    qc => $q_stats,
    source => \%s_data,
    taxonomy => $taxa,
    function => PipelineAnalysis::get_ontology_abundances($adbh, $job_id, $ann_ver),
    ontology => PipelineAnalysis::get_function_abundances($adbh, $job_id, $ann_ver),
    rarefaction => PipelineAnalysis::get_rarefaction_xy($adbh, $job_id, $job_stats->{sequence_count_raw}, $ann_ver),
    sequence_stats => $job_stats
};
# output stats object
PipelineAWE::print_json($job_id.".statistics.json", $mgstats);
PipelineAWE::create_attr($job_id.".statistics.json.attr", undef, {data_type => "statistics", file_format => "json"});

# upload of solr data
my $done_attr = PipelineAWE::read_json($PipelineAWE::global_attr);
my $solr_file = solr_dump($job_id, $seq_type, $done_attr, $mgstats, $filter);
solr_post($solr_url, $solr_col, $solr_file);

exit(0);

sub get_usage {
    return "USAGE: awe_done.pl -job=<job identifier>\n";
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
        my $ratio_guess = ($rna_ratio > 0.25) ? 'MT' : 'WGS';
        return $ratio_guess;
    }
}

sub solr_dump {
    my ($job, $seq_type, $mginfo, $mgstats, $sims) = @_;
    my $sfile = $job.'.solr.json';
    open(SOLR, ">$sfile") || exit __LINE__;
    # top level data
    print SOLR "[\n{\n";
    print SOLR "   \"job\" : \"$job\",\n";
    print SOLR "   \"id\" : \"".$mginfo->{metagenome_id}."\",\n";
    print SOLR "   \"id_sort\" : \"".$mginfo->{metagenome_id}."\",\n";
    print SOLR "   \"status\" : \"".$mginfo->{status}."\",\n";
    print SOLR "   \"status_sort\" : \"".$mginfo->{status}."\",\n";
    print SOLR "   \"created\" : \"".$mginfo->{created}."\",\n";
    print SOLR "   \"name\" : \"".$mginfo->{name}."\",\n";
    print SOLR "   \"name_sort\" : \"".$mginfo->{name}."\",\n";
    print SOLR "   \"project_id\" : \"".$mginfo->{project_id}."\",\n";
    print SOLR "   \"project_id_sort\" : \"".$mginfo->{project_id}."\",\n";
    print SOLR "   \"project_name\" : \"".$mginfo->{project_name}."\",\n";
    print SOLR "   \"project_name_sort\" : \"".$mginfo->{project_name}."\",\n";
    print SOLR "   \"sequence_type\" : \"".$mginfo->{sequence_type}."\",\n";
    print SOLR "   \"seq_method\" : \"$seq_type\",\n";
    print SOLR "   \"version\" : 1,\n";
    # seq stats
    foreach my $stat (keys %{$mgstats->{sequence_stats}}) {
        if ($stat =~ /count/ || $stat =~ /min/ || $stat =~ /max/) {
            print SOLR "   \"$stat\_l\" : \"".$mgstats->{sequence_stats}{$stat}."\",\n";
        } else {
            print SOLR "   \"$stat\_d\" : \"".$mgstats->{sequence_stats}{$stat}."\",\n";
        }
    }
    # functions
    my $count = 0;
    print SOLR "   \"function\" : [\n";
    foreach my $func (@{$mgstats->{function}}) {
        $count++;
        my $name = $func[0];
        $name =~ s/\\/\\\\/g;
        $name =~ s/"/\\"/g;
        if ($count == 1) {
            print SOLR "      \"$name\"";
        } else {
            print SOLR ",\n      \"$name\"";
        }
    }
    # organisms
    $count = 0;
    print SOLR "\n   ],\n   \"organism\" : [\n";
    foreach my $org (@{$mgstats->{taxonomy}{species}}) {
        $count++;
        my $name = $org[0];
        $name =~ s/\\/\\\\/g;
        $name =~ s/"/\\"/g;
        if ($count == 1) {
            print SOLR "      \"$name\"";
        } else {
            print SOLR ",\n      \"$name\"";
        }
    }
    # md5s
    my $last_md5 = "";
    $count = 0;
    print SOLR "\n   ],\n   \"md5\" : [\n";
    open(MD5S, "<$sims") or exit __LINE__;
    while (my $line = <MD5S>) {
        chomp $line;
        $count++;
        my @array = split(/\t/, $line);
        if ($count == 1) {
            print SOLR "      \"$array[1]\"";
        } elsif ($array[1] ne $last_md5) {
            print SOLR ",\n      \"$array[1]\"";
        }
        $last_md5 = $array[1];
    }
    print SOLR "\n   ]\n}\n]";
    close(MD5S);
    close(SOLR);
    return $sfile;
}

sub solr_post {
    my ($solr_url, $solr_col, $solr_file) = @_;
    my $post_url = "http://$solr_url/solr/$solr_col/update/json?commit=true";
    my $req = HTTP::Request::StreamingUpload->new(
        POST => $post_url,
        path => $solr_file,
        headers => HTTP::Headers->new(
            'Content-Type' => 'application/json',
            'Content-Length' => -s $solr_fn,
        )
    );
    my $response = LWP::UserAgent->new->request($req);
    if ($response->{"_msg"} ne 'OK') {
        my $content = $response->{"_content"};
        print STDERR "solr POST failed: ".$content."\n";
        exit 1;
    }
}
