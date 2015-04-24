#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use PipelineJob;
use PipelineAnalysis;
use StreamingUpload;

use Scalar::Util qw(looks_like_number);
use URI::Escape;
use Getopt::Long;
umask 000;

# options
my $job_id    = "";
my $psql      = "";
my $mysql     = "";
my $nr_ver    = "";
my $ann_ver   = "";
my $api_url   = "";
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
		"psql=s"      => \$psql,
		"mysql=s"     => \$mysql,
		"nr_ver=s"    => \$nr_ver,
		"ann_ver=s"   => \$ann_ver,
		"api_url=s"   => \$api_url,
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
    exit 1;
}elsif (! -e $psql){
    print STDERR "ERROR: The input postgresql file [$psql] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! -e $mysql){
    print STDERR "ERROR: The input mysql file [$mysql] does not exist.\n";
    print STDERR get_usage();
    exit 1;
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
unless ( defined($jdbhost) && defined($jdbname) && defined($jdbuser) && defined($jdbpass) ) {
    print STDERR "ERROR: missing job info database ENV variables.\n";
    print STDERR get_usage();
    exit 1;
}
unless ( defined($adbhost) && defined($adbname) && defined($adbuser) && defined($adbpass) ) {
    print STDERR "ERROR: missing analysis database ENV variables.\n";
    print STDERR get_usage();
    exit 1;
}

# get solr variables
my $solr_url = $ENV{'SOLR_SERVER'} || undef;
my $solr_col = $ENV{'SOLR_COLLECTION'} || undef;
unless ( defined($solr_url) && defined($solr_col) ) {
    print STDERR "ERROR: missing solr server ENV variable.\n";
    print STDERR get_usage();
    exit 1;
}

# get api variable
my $api_key = $ENV{'MGRAST_WEBKEY'} || undef;

# place certs in home dir
PipelineAWE::run_cmd('tar --no-same-owner --no-same-permissions -xf '.$psql.' -C '.$ENV{'HOME'}, 1);
PipelineAWE::run_cmd('tar --no-same-owner --no-same-permissions -xf '.$mysql.' -C '.$ENV{'HOME'}, 1);
my $mspath = $ENV{'HOME'}.'/.mysql/';

# get db handles
my $jdbh = PipelineJob::get_jobcache_dbh($jdbhost, $jdbname, $jdbuser, $jdbpass, $mspath.'client-key.pem', $mspath.'client-cert.pem', $mspath.'ca-cert.pem');
my $adbh = PipelineAnalysis::get_analysis_dbh($adbhost, $adbname, $adbuser, $adbpass);

### update attribute stats
# get attributes
print "Computing file statistics and updating attributes\n";
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

### JobDB update
# get JobDB statistics
print "Retrieving sequence statistics from attributes\n";
my $job_stats = PipelineJob::get_job_statistics($jdbh, $job_id);
# get additional attributes
my $up_attr = PipelineAWE::read_json($upload.'.json');
my $qc_attr = PipelineAWE::read_json($qc.'.json');
my $de_attr = PipelineAWE::read_json($derep.'.json');
my $pp_attr = PipelineAWE::read_json($preproc.'.json');
my $fl_attr = PipelineAWE::read_json($filter.'.json');
my $on_attr = PipelineAWE::read_json($ontol.'.json');
# populate job_stats
$job_stats->{sequence_count_dereplication_removed} = $de_attr->{statistics}{sequence_count} || '0';  # derep fail
$job_stats->{alpha_diversity_shannon}  = PipelineAnalysis::get_alpha_diversity($adbh, $job_id, $ann_ver);
$job_stats->{read_count_processed_rna} = $sr_attr->{statistics}{sequence_count} || '0';      # pre-cluster / rna search
$job_stats->{read_count_processed_aa}  = $gc_attr->{statistics}{sequence_count} || '0';      # pre-cluster / genecall
$job_stats->{sequence_count_processed_rna} = $rc_attr->{statistics}{sequence_count} || '0';  # post-cluster / rna clust
$job_stats->{sequence_count_processed_aa}  = $ac_attr->{statistics}{sequence_count} || '0';  # post-cluster / aa clust
map { $job_stats->{$_} = $qc_attr->{statistics}{$_} } keys %{$qc_attr->{statistics}};        # qc stats
map { $job_stats->{$_} = $fl_attr->{statistics}{$_} } keys %{$fl_attr->{statistics}};        # sims filter stats
map { $job_stats->{$_} = $on_attr->{statistics}{$_} } keys %{$on_attr->{statistics}};        # annotate ontology stats
map { $job_stats->{$_.'_raw'} = $up_attr->{statistics}{$_} } keys %{$up_attr->{statistics}}; # raw seq stats
map { $job_stats->{$_.'_preprocessed_rna'} = $pp_attr->{statistics}{$_} } keys %{$pp_attr->{statistics}};  # preprocess seq stats
map { $job_stats->{$_.'_preprocessed'}     = $pq_attr->{statistics}{$_} } keys %{$pq_attr->{statistics}};  # screen seq stats
map { $job_stats->{$_.'_processed_rna'}    = $rm_attr->{statistics}{$_} } keys %{$rm_attr->{statistics}};  # rna clust stats
map { $job_stats->{$_.'_processed_aa'}     = $am_attr->{statistics}{$_} } keys %{$am_attr->{statistics}};  # aa clust stats
# read ratios
my ($aa_ratio, $rna_ratio) = read_ratios($job_stats);
$job_stats->{ratio_reads_aa} = $aa_ratio;
$job_stats->{ratio_reads_rna} = $rna_ratio;

# get sequence type
my $job_attrs = PipelineJob::get_job_attributes($jdbh, $job_id);
my $seq_type  = seq_type($job_attrs, $rna_ratio);

# get versions
my $m5nr_vers = {
    m5rna_sims_version => $nr_ver,
    m5nr_sims_version  => $nr_ver,
    m5rna_annotation_version => $ann_ver,
    m5nr_annotation_version  => $ann_ver
};

# update DB
print "Updating Job DB with new stats / info\n";
PipelineJob::set_job_statistics($jdbh, $job_id, $job_stats);
PipelineJob::set_job_attributes($jdbh, $job_id, $m5nr_vers);
PipelineJob::set_jobcache_info($jdbh, $job_id, 'sequence_type', $seq_type);
if ($up_attr->{statistics}{file_size}) {
    PipelineJob::set_jobcache_info($jdbh, $job_id, 'file_size_raw', $up_attr->{statistics}{file_size});
}

### create metagenome statistics node
# get stats from inputs
print "Building / computing metagenome statistics file\n";
my $u_stats = PipelineAWE::read_json($upload);
my $q_stats = PipelineAWE::read_json($qc);
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
        post_qc => PipelineAWE::file_to_array("$post_qc.stats.gcs")
    },
    length_histogram => {
        upload  => $u_stats->{length_histogram},
        post_qc => PipelineAWE::file_to_array("$post_qc.stats.lens")
    },
    qc => $q_stats,
    source => \%s_data,
    taxonomy => $taxa,
    function => PipelineAnalysis::get_function_abundances($adbh, $job_id, $ann_ver),
    ontology => PipelineAnalysis::get_ontology_abundances($adbh, $job_id, $ann_ver),
    rarefaction => PipelineAnalysis::get_rarefaction_xy($adbh, $job_id, $job_stats->{sequence_count_raw}, $ann_ver),
    sequence_stats => $job_stats
};
# output stats object
print "Outputing statistics file\n";
PipelineAWE::print_json($job_id.".statistics.json", $mgstats);
PipelineAWE::create_attr($job_id.".statistics.json.attr", undef, {data_type => "statistics", file_format => "json"});

# upload of solr data
print "Outputing and POSTing solr file\n";
my $done_attr = PipelineAWE::get_userattr();
my $metadata  = PipelineAWE::get_metadata($done_attr->{id}, $api_url, $api_key);
my $solr_file = solr_dump($job_id, $seq_type, $job_attrs, $done_attr, $mgstats, $metadata);
solr_post($solr_url, $solr_col, $solr_file);

# done done !!
PipelineJob::set_jobcache_info($jdbh, $job_id, 'viewable', 1);

# cleanup
#PipelineAWE::run_cmd('rm -rf '.$ENV{'HOME'}.'/.postgresql');
#PipelineAWE::run_cmd('rm -rf '.$ENV{'HOME'}.'/.mysql');

exit 0;

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
        return ($rna_ratio > 0.25) ? 'MT' : 'WGS';
    }
}

sub solr_dump {
    my ($job, $seq_type, $jobattr, $mginfo, $mgstats, $metadata) = @_;
    
    # top level data
    my $mgid = $mginfo->{id};
    my $solr_data = {
        job                => int($job),
        id                 => $mgid,
        id_sort            => $mgid,
        status             => $mginfo->{status},
        status_sort        => $mginfo->{status},
        created            => solr_time_format($mginfo->{created}),
        created_sort       => solr_time_format($mginfo->{created}),
        name               => $mginfo->{name},
        name_sort          => $mginfo->{name},
        project_id         => $mginfo->{project_id},
        project_id_sort    => $mginfo->{project_id},
        project_name       => $mginfo->{project_name},
        project_name_sort  => $mginfo->{project_name},
        sequence_type      => $seq_type,
        sequence_type_sort => $seq_type,
        seq_method         => $jobattr->{sequencing_method_guess},
        seq_method_sort    => $jobattr->{sequencing_method_guess},
        version            => 1,
        function           => [ map {$_->[0]} @{$mgstats->{function}} ],
        organism           => [ map {$_->[0]} @{$mgstats->{taxonomy}{species}} ],
        md5                => [ keys %{$PipelineAnalysis::md5_abundance} ]
    };
    # seq stats
    while (my ($key, $val) = each(%{$mgstats->{sequence_stats}})) {
        if (looks_like_number($val)) {
            if ($key =~ /count/ || $key =~ /min/ || $key =~ /max/) {
                $solr_data->{$key.'_l'} = $val * 1;
            } else {
                $solr_data->{$key.'_d'} = $val * 1.0;
            }
        }
    }
    # mixs metadata
    if ($metadata && exists($metadata->{mixs})) {
        while (my ($key, $val) = each(%{$metadata->{mixs}})) {
            if ($val) {
                $solr_data->{$key} = $val;
                $solr_data->{$key.'_sort'} = $val;
            }
        }
    }
    # full metadata
    foreach my $cat (('project', 'sample', 'env_package', 'library')) {
        eval {
            if ($metadata && exists($metadata->{$cat}) && $metadata->{$cat}{id} && $metadata->{$cat}{name} && $metadata->{$cat}{data}) {
                $solr_data->{$cat.'_id'} = $metadata->{$cat}{id};
                $solr_data->{$cat.'_id_sort'} = $metadata->{$cat}{id};
                $solr_data->{$cat.'_name'} = $metadata->{$cat}{name};
                $solr_data->{$cat} = join(", ", @{$metadata->{$cat}{data}});
            }
        };
    }
    
    # print
    my $solr_str  = $PipelineAWE::json->encode($solr_data);
    my $solr_file = $job.'.solr.json';
    open(SOLR, ">$solr_file") or die "Couldn't open file: $!";
    print SOLR qq({
    "delete": { "id": "$mgid" },
    "commit": { "expungeDeletes": "true" },
    "add": {
        "doc": $solr_str
    }
});
    close(SOLR);
    return $solr_file;
}

sub solr_post {
    my ($solr_url, $solr_col, $solr_file) = @_;
    
    # post commands and data
    my $post_url = "$solr_url/solr/$solr_col/update/json?commit=true";
    my $req = StreamingUpload->new(
        POST => $post_url,
        path => $solr_file,
        headers => HTTP::Headers->new(
            'Content-Type' => 'application/json',
            'Content-Length' => -s $solr_file,
        )
    );
    my $response = $PipelineAWE::agent->request($req);
    if ($response->{"_msg"} ne 'OK') {
        my $content = $response->{"_content"};
        print STDERR "solr POST failed: ".$content."\n";
        exit 1;
    }
}

sub solr_time_format {
    my ($dt) = @_;
    if ($dt =~ /^(\d{4}\-\d\d\-\d\d)[ T](\d\d\:\d\d\:\d\d)/) {
        $dt = $1.'T'.$2.'Z';
    } elsif ($dt =~ /^(\d{4}\-\d\d\-\d\d)/) {
        $dt = $1.'T00:00:00Z'
    }
    return $dt;
}
