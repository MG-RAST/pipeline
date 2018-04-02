#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use File::Basename;
use Data::Dumper;
use Cwd;
umask 000;

# rRNA list
my @rnas = (
    '28S',  # Eukaryotic LSU
    '23S',  # Prokaryotic LSU, Plastid LSU
    '18S',  # Eukaryotic SSU
    '16S',  # Prokaryotic SSU, Plastid SSU, Mitochondrial LSU
    '12S',  # Mitochondrial SSU
    'ITS'   # internal transcribed spacer
);
# seq type map
my %seqmap = (
    'metagenome'        => 'WGS',
    'metatranscriptome' => 'MT',
    'mimarks-survey'    => 'Amplicon'
);

# options
my $input     = "";
my $metadata  = "";
my $project   = "";
my $help      = 0;
my $options   = GetOptions (
    "input=s"     => \$input,
    "metadata=s"  => \$metadata,
    "project=s"   => \$project,
    "help!"       => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($input)==0){
    PipelineAWE::logger('error', "input parameters file was not specified");
    exit 1;
}elsif (! -e $input){
    PipelineAWE::logger('error', "input parameters file [$input] does not exist");
    exit 1;
}

my $params = PipelineAWE::read_json($input);
my $mdata  = ($metadata && (-s $metadata)) ? PipelineAWE::read_json($metadata) : undef;

unless ($mdata || $project) {
    PipelineAWE::logger('error', "must have one of --metadata or --project");
    exit 1;
}

my $auth = $ENV{'USER_AUTH'} || undef;
my $api  = $ENV{'MGRAST_API'} || undef;
unless ($auth && $api) {
    PipelineAWE::logger('error', "missing authentication ENV variables");
    exit 1;
}

# get inbox list
my $inbox = PipelineAWE::obj_from_url($api."/inbox", $auth);
my %seq_files = map { $_->{filename}, $_ } grep { exists($_->{data_type}) && ($_->{data_type} eq 'sequence') } @{$inbox->{files}};

my $is_valid    = {}; # file_name w/o extension => file_name
my $to_submit   = {}; # file_name => [ mg_name, sequence_type ]
my $no_inbox    = {}; # file_name
my $min_seq     = {}; # file_name
my $min_bp      = {}; # file_name
my $max_length  = {}; # file_name
my $no_metadata = {}; # file_name

# check that input files in inbox and right sizes
foreach my $file (@{$params->{input}{files}}) {
    my $fname = $file->{filename};
    unless (exists($file->{stats_info}{sequence_count}) && exists($file->{stats_info}{bp_count})) {
        $no_inbox->{$fname} = 1;
        next;
    }
    if (int($file->{stats_info}{sequence_count}) < 100) {
        $min_seq->{$fname} = 1;
        next;
    }
    if (int($file->{stats_info}{bp_count}) < 1000000) {
        $min_bp->{$fname} = 1;
        next;
    }
    if (int($file->{stats_info}{length_max}) > 500000) {
        $max_length->{$fname} = 1;
        next;
    }
    if (exists $seq_files{$fname}) {
        my $basename = fileparse($fname, qr/\.[^.]*/);
        $is_valid->{$basename} = $fname;
        next;
    }
    $no_inbox->{$fname} = 1;
}
foreach my $miss (keys %$no_inbox) {
    print STDOUT "not_in_inbox\t$miss\n";
}
foreach my $miss (keys %$min_seq) {
    print STDOUT "below_min_seq_count\t$miss\n";
}
foreach my $miss (keys %$min_bp) {
    print STDOUT "below_min_bp_count\t$miss\n";
}
foreach my $miss (keys %$max_length) {
    print STDOUT "above_max_seq_length\t$miss\n";
}

# populate to_submit from is_valid
# if metadata, check that input files in metadata
# extract metagenome names
# need to create project before submitted
if ($mdata && $params->{metadata}) {
    if ($mdata->{id} && ($mdata->{id} =~ /^mgp/)) {
        $project = $mdata->{id};
    }
    my %md_names = (); # file w/o extension => [ mg_name, sequence_type ]
    foreach my $sample ( @{$mdata->{samples}} ) {
        next unless ($sample->{libraries} && scalar(@{$sample->{libraries}}));
        foreach my $library (@{$sample->{libraries}}) {
            next unless (exists $library->{data});
            my $mg_name = "";
            my $file_name = "";
            if (exists $library->{data}{metagenome_name}) {
                $mg_name = $library->{data}{metagenome_name}{value};
            }
            if (exists $library->{data}{file_name}) {
                $file_name = fileparse($library->{data}{file_name}{value}, qr/\.[^.]*/);
            } else {
                $file_name = $mg_name;
            }
            if ($mg_name && $file_name) {
                my $seq_type = undef;
                if (exists($library->{data}{investigation_type}) && exists($seqmap{$library->{data}{investigation_type}{value}})) {
                    $seq_type = $seqmap{$library->{data}{investigation_type}{value}};
                    if (exists($library->{data}{target_gene}) && $library->{data}{target_gene}{value}) {
                        $seq_type = 'Metabarcode';
                        foreach my $r (@rnas) {
                            if ($library->{data}{target_gene}{value} =~ /$r/) {
                                $seq_type = 'Amplicon';
                            }
                        }
                    }
                }
                $md_names{$file_name} = [$mg_name, $seq_type];
            }
        }
    }
    while (my ($basename, $fname) = each %$is_valid) {
        if (exists $md_names{$basename}) {
            $to_submit->{$fname} = $md_names{$basename};
        } else {
            $no_metadata->{$fname} = 1;
        }
    }
    foreach my $miss (keys %$no_metadata) {
        print STDOUT "no_metadata\t$miss\n";
    }
}
if ($project) {
    unless ($mdata && $params->{metadata}) {
        while (my ($basename, $file_name) = each %$is_valid) {
            $to_submit->{$file_name} = [$basename, undef];
        }
    }
    my $pinfo = PipelineAWE::obj_from_url($api."/project/".$project, $auth);
    unless ($project eq $pinfo->{id}) {
        PipelineAWE::logger('error', "project $project does not exist");
    }
} else {
    PipelineAWE::logger('error', "project ID is missing");
}

my $submitted = {}; # file_name => [name, awe_id, mg_id]

# submit one at a time / add to project as submitted
my $mgids = [];
FILES: foreach my $fname (keys %$to_submit) {
    my $info = $seq_files{$fname};
    my $metagenome_name = $to_submit->{$fname}[0];
    my $sequence_type = $to_submit->{$fname}[1];
    # see if already exists for this submission (due to re-start)
    my $mg_by_md5 = PipelineAWE::obj_from_url($api."/metagenome/md5/".$info->{stats_info}{checksum}, $auth);
    if ($mg_by_md5 && ($mg_by_md5->{total_count} > 0)) {
        foreach my $mg (@{$mg_by_md5->{data}}) {
            next if ($mg->{status} =~ /deleted/);
            if ($mg->{submission} && ($mg->{submission} eq $params->{submission})) {
                PipelineAWE::logger('warn', $mg->{id}." already exists, re-submitting");
                my $awe_id = exists($mg->{pipeline_id}) ? $mg->{pipeline_id} : "";
                # not in pipeline
                if (! $awe_id) {
                    # not properly created, redo
                    if (! $mg->{project}) {
                        PipelineAWE::logger('warn', $mg->{id}." has no project, re-creating");
                        my $create_data = $params->{parameters};
                        $create_data->{metagenome_id} = $mg->{id};
                        $create_data->{input_id}      = $info->{id};
                        $create_data->{submission}    = $params->{submission};
                        if ($sequence_type) {
                            $create_data->{sequence_type} = $sequence_type;
                        }
                        my $create_job = PipelineAWE::post_data($api."/job/create", $auth, $create_data);
                        PipelineAWE::post_data($api."/job/addproject", $auth, {metagenome_id => $mg->{id}, project_id => $project});
                    }
                    # fully created but not in pipeline, submit it
                    my $submit_job = PipelineAWE::post_data($api."/job/submit", $auth, {metagenome_id => $mg->{id}, input_id => $info->{id}});
                    $awe_id = $submit_job->{awe_id};
                }
                # submitted: add to set and process next
                $submitted->{$fname} = [$mg->{name}, $awe_id, $mg->{id}];
                print STDOUT join("\t", ("submitted", $fname, $mg->{name}, $awe_id, $mg->{id}))."\n";
                push @$mgids, $mg->{id};
                next FILES;
            }
        }
    }
    # reserve and create job
    my $reserve_job = PipelineAWE::post_data($api."/job/reserve", $auth, {name => $metagenome_name, input_id => $info->{id}});
    my $mg_id = $reserve_job->{metagenome_id};
    my $create_data = $params->{parameters};
    $create_data->{metagenome_id} = $mg_id;
    $create_data->{input_id}      = $info->{id};
    $create_data->{submission}    = $params->{submission};
    if ($sequence_type) {
        $create_data->{sequence_type} = $sequence_type;
    }
    my $create_job = PipelineAWE::post_data($api."/job/create", $auth, $create_data);
    # project
    PipelineAWE::post_data($api."/job/addproject", $auth, {metagenome_id => $mg_id, project_id => $project});
    # submit it
    my $submit_job = PipelineAWE::post_data($api."/job/submit", $auth, {metagenome_id => $mg_id, input_id => $info->{id}});
    $submitted->{$fname} = [$metagenome_name, $submit_job->{awe_id}, $mg_id];
    print STDOUT join("\t", ("submitted", $fname, $metagenome_name, $submit_job->{awe_id}, $mg_id))."\n";
    push @$mgids, $mg_id;
}

if (@$mgids == 0) {
    PipelineAWE::logger('error', "no metagenomes created for submission");
    exit 1;
}

# apply metadata
if ($mdata && $params->{metadata}) {
    my $import = {node_id => $params->{metadata}, metagenome => $mgids};
    my $result = PipelineAWE::post_data($api."/metadata/import", $auth, $import);
    # no success
    if (scalar(@{$result->{added}}) == 0) {
        if ($result->{errors} && (@{$result->{errors}} > 0)) {
            PipelineAWE::logger('error', "unable to import metadata: ".join(", ", @{$result->{errors}}));
        } else {
            PipelineAWE::logger('error', "unable to import any metadata");
        }
        exit 1;
    }
    # partial success
    if (scalar(@{$result->{added}}) < scalar(@$mgids)) {
        my %success = map { $_, 1 } @{$result->{added}};
        my @list = ();
        foreach my $m (@$mgids) {
            unless ($success{$m}) {
                push @list, $m;
            }
        }
        if (@list > 0) {
            PipelineAWE::logger('error', "unable to import metadata for the following: ".join(", ", @list));
        }
    }
}

sub get_usage {
    return "USAGE: mgrast_submit.pl -input=<pipeline parameter file> [-metadata=<metadata file>, -project=<project id>]\n";
}
