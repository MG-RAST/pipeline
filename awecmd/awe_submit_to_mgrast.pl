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
    print STDERR "ERROR: An input cluster map file was not specified.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! -e $input){
    print STDERR "ERROR: The input cluster map file [$in_clust] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}

my $params = PipelineAWE::read_json($input);
my $mdata  = ($metadata && (-s $metadata)) ? PipelineAWE::read_json($metadata) : undef;

unless ($mdata || $project) {
    print STDERR "ERROR: Must have one of -metadata or -project.\n";
    print STDERR get_usage();
    exit 1;
}

my $auth = $ENV{'USER_AUTH'} || undef;
my $api  = $ENV{'MGRAST_API'} || undef;
unless ($auth && $api) {
    print STDERR "ERROR: Missing authentication ENV variables.\n";
    print STDERR get_usage();
    exit 1;
}

# get inbox list
my $inbox = PipelineAWE::obj_from_url($api."/inbox", $auth);
my %seq_files = map { $_->{filename}, $_ } grep { exists($_->{data_type}) && ($_->{data_type} eq 'sequence') } @{$inbox->{files}};

my $to_submit   = {}; # file_name => mg_name
my $no_inbox    = {}; # file_name
my $no_metadata = {}; # file_name

# check that input files in inbox
foreach my $fname (@{$params->{files}}) {
    if (exists $seq_files{$fname}) {
        $to_submit->{$fname} = fileparse($fname, qr/\.[^.]*/);
    } else {
        $no_inbox->{$fname} = 1;
    }
}
print STDOUT "no_inbox\t".join("\t", keys %$no_inbox)."\n";

# if metadata, check that input files in metadata
if ($mdata) {
    my %md_names = ();
    foreach my $sample ( @{$mdata->{samples}} ) {
        next unless ($sample->{libraries} && scalar(@{$sample->{libraries}}));
        foreach my $library (@{$sample->{libraries}}) {
            next unless (exists $library->{data});
            my $mg_name = "";
            my $file_name = "";
            if (exists $library->{data}{file_name}) {
                $file_name = $library->{data}{file_name}{value};
                $mg_name = fileparse($library->{data}{file_name}{value}, qr/\.[^.]*/);
            }
            if (exists $library->{data}{metagenome_name}) {
                $mg_name = $library->{data}{metagenome_name}{value};
            }
            if ($mg_name && $file_name) {
                $md_names{$file_name} = $mg_name;
            }
        }
    }
    foreach my $fname (@{$params->{files}}) {        
        if (exists $md_names{$fname}) {
            # update filename
            $to_submit->{$fname} = $md_names{$fname};
        } else {
            # remove from list
            $no_metadata->{$fname} = 1;
            if ($to_submit->{$fname}) {
                delete $to_submit->{$fname};
            }
        }
    }
    print STDOUT "no_metadata\t".join("\t", keys %$no_metadata)."\n";
}

my $submitted = {}; # file_name => [name, awe_id, mg_id]
print STDOUT "submitted\n";

# submit one at a time
FILES: foreach my $fname (keys %$to_submit) {
    my $info = $seq_files{$fname};
    # see if already exists for this submission (due to re-start)
    my $mg_by_md5 = PipelineAWE::obj_from_url($api."/metagenome/md5/".$info->{stats_info}{checksum}, $auth);
    if ($mg_by_md5 && ($mg_by_md5->{total_count} > 0)) {
        foreach my $mg (@{$mg_by_md5->{data}}) {
            if ($mg->{submission} && ($mg->{submission} eq $params->{submission})) {
                my $awe_id = exists($mg->{pipeline_id}) ? $mg->{pipeline_id} : "";
                $submitted->{$fname} = [$mg->{name}, $awe_id, $mg->{id}];
                print STDOUT join("\t", ($fname, $mg->{name}, $awe_id, $mg->{id}))."\n";
                next FILES;
            }
        }
    }
    # reserve and create job
    my $reserve_job = PipelineAWE::obj_from_url($api."/job/reserve", $auth, {name => $to_submit->{$fname}, input_id => $info->{id}});
    my $mg_id = $reserve_job->{metagenome_id}
    my $create_data = $params->{parameters};
    $create_data->{metagenome_id} = $mg_id;
    $create_data->{input_id}      = $info->{id};
    $create_data->{submission}    = $params->{submission};
    my $create_job = PipelineAWE::obj_from_url($api."/job/create", $auth, $create_data);
    # submit it
    my $submit_job = PipelineAWE::obj_from_url($api."/job/submit", $auth, {metagenome_id => $mg_id, input_id => $info->{id}});
    $submitted->{$fname} = [$to_submit->{$fname}, $submit_job->{awe_id}, $mg_id];
    print STDOUT join("\t", ($fname, $to_submit->{$fname}, $submit_job->{awe_id}, $mg_id))."\n";
}


sub get_usage {
    return "USAGE: awe_submit_to_mgrast.pl -params=<pipeline parameters> [-metadata=<metadata file>, -project=<project id>]\n";
}
