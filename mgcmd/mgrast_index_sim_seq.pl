#!/usr/bin/env perl 

#input: .sims file(s), .mapping files(s), sequence file
#outputs: $output, ${output}.index, ${output}.json

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use Cwd;
umask 000;

# options
my $api_url = "";
my @in_sims = ();
my @in_maps = ();
my @in_seqs = ();
my $output  = "";
my $memory  = 16;
my $help    = 0;
my $options = GetOptions (
    "api_url=s"  => \$api_url,
    "in_sims=s"  => \@in_sims,
    "in_maps=s"  => \@in_maps,
    "in_seqs=s"  => \@in_seqs,
    "output=s"   => \$output,
    "memory=i"   => \$memory,
    "help!"      => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (scalar(@in_sims)==0){
    PipelineAWE::logger('error', "at least one input similarity file is required");
    exit 1;
}elsif (scalar(@in_maps)==0){
    PipelineAWE::logger('error', "at least one input mapping file is required");
    exit 1;
}elsif (scalar(@in_seqs)==0){
    PipelineAWE::logger('error', "input file was not specified");
    exit 1;
}elsif (length($output)==0){
    PipelineAWE::logger('error', "output file was not specified");
    exit 1;
}

unless ($api_url) {
    $api_url = $PipelineAWE::default_api;
}

# get api variable
my $api_key = $ENV{'MGRAST_WEBKEY'} || undef;

# temp files
my $sim_file = "sims.filter.".time();
my $map_file = "mapping.".time();
my $seq_file = "sequence.".time();

# cat file sets
if (@in_sims > 1) {
    PipelineAWE::run_cmd("cat ".join(" ", @in_sims)." > ".$sim_file, 1);
    PipelineAWE::run_cmd("rm ".join(" ", @in_sims));
} else {
    PipelineAWE::run_cmd("mv ".$in_sims[0]." ".$sim_file);
}
if (@in_maps > 1) {
    PipelineAWE::run_cmd("cat ".join(" ", @in_maps)." > ".$map_file, 1);
    PipelineAWE::run_cmd("rm ".join(" ", @in_maps));
} else {
    PipelineAWE::run_cmd("mv ".$in_maps[0]." ".$map_file);
}
if (@in_seqs > 1) {
    PipelineAWE::run_cmd("cat ".join(" ", @in_seqs)." > ".$seq_file, 1);
    PipelineAWE::run_cmd("rm ".join(" ", @in_seqs));
} else {
    PipelineAWE::run_cmd("mv ".$in_seqs[0]." ".$seq_file);
}

my $mem = $memory * 1024;
my $run_dir = getcwd;

# file is empty !!!
if (-z $sim_file) {
    my $user_attr = PipelineAWE::get_userattr();
    my $job_name  = $user_attr->{name};
    my $job_id    = $user_attr->{id};
    my $proj_name = $user_attr->{project_name};
    my $subject   = "MG-RAST Job Failed";
    my $body_txt  = qq(
The annotation job that you submitted for $job_name ($job_id) belonging to study $proj_name has failed.
No similarities were found using blat against our M5NR database.

This is an automated message.  Please contact help\@mg-rast.org if you have any questions or concerns.
);
    PipelineAWE::post_data($api_url."/user/".$user_attr->{owner}."/notify", $api_key, {'subject' => $subject, 'body' => $body_txt});
    PipelineAWE::logger('error', "pipeline failed, no similarities found");
    # exit failed-permanent
    exit 42;
}

PipelineAWE::run_cmd("uncluster_sims.py -v -c $map_file -i $sim_file -o $sim_file.unclust");
PipelineAWE::run_cmd("rm $sim_file $map_file");
PipelineAWE::run_cmd("seqUtil -t $run_dir -i $seq_file -o $seq_file.tab --sortbyid2tab");
PipelineAWE::run_cmd("rm $seq_file");
PipelineAWE::run_cmd("sort -T $run_dir -S ${mem}M -t \t -k 1,1 -o $sim_file.sort $sim_file.unclust");
PipelineAWE::run_cmd("rm $sim_file.unclust");
PipelineAWE::run_cmd("add_seq2sims -v -i $sim_file.sort -o $sim_file.seq -s $seq_file.tab");
PipelineAWE::run_cmd("rm $sim_file.sort $seq_file.tab");
PipelineAWE::run_cmd("sort -T $run_dir -S ${mem}M -t \t -k 2,2 -o $sim_file.final $sim_file.seq");
PipelineAWE::run_cmd("rm $sim_file.seq");

# index file
PipelineAWE::run_cmd("index_sims_file_md5 --verbose --in_file $sim_file.final --out_file $sim_file.index");

# final output
PipelineAWE::run_cmd("mv $sim_file.final $output");
PipelineAWE::run_cmd("mv $sim_file.index $output.index");

# get stats
my $ann_read = `cut -f1 $output | sort -u | wc -l`;
chomp $ann_read;
my $sim_stat = {read_count_annotated => $ann_read};
foreach my $sim (@in_sims) {
    my $sim_attr = PipelineAWE::read_json($sim.'.json');
    if ($sim_attr->{statistics} && ref($sim_attr->{statistics})) {
        map { $sim_stat->{$_} = $sim_attr->{statistics}{$_} } keys %{$sim_attr->{statistics}};
    }
}

# output attributes
PipelineAWE::create_attr($output.'.json', $sim_stat, {data_type => "similarity", file_format => "blast m8", sim_type => "filter"});
PipelineAWE::create_attr($output.'.index.json', undef, {data_type => "index", file_format => "text"});

exit 0;

sub get_usage {
    return "USAGE: mgrast_index_sim_seq.pl -in_sims=<one or more input sim files> -in_maps=<one or more input mapping files> -in_seqs=<one or more input fasta files> -output=<output file> [-memory=<memory usage in GB, default is 16>\noutputs: \${output} and \${output}.index\n";
}
