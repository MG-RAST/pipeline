#!/usr/bin/env perl

#input: .fna or .fastq
#outputs:  ${out_prefix}.passed.fna, ${out_prefix}.removed.fna

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use Cwd;
umask 000;

# options
my $api_url    = "";
my $input_file = "";
my $format     = "";
my $out_prefix = "prep";
my $filter_options = "";
my $do_not_create_index_files = 0 ;
my $help = 0;
my $options = GetOptions (
    "api_url=s" => \$api_url,
    "input=s" => \$input_file,
    "format=s" => \$format,
    "out_prefix=s" => \$out_prefix,
    "filter_options=s" => \$filter_options,
    "no-shock" => \$do_not_create_index_files,
    "help!" => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($input_file)==0){
    PipelineAWE::logger('error', "input file was not specified");
    exit 1;
}elsif (! -e $input_file){
    PipelineAWE::logger('error', "input sequence file [$input_file] does not exist");
    exit 1;
}

unless ($api_url) {
    $api_url = $PipelineAWE::default_api;
}

# get api variable
my $api_key = $ENV{'MGRAST_WEBKEY'} || undef;

unless ($format && ($format =~ /^fasta|fastq$/)) {
    $format = ($input_file =~ /\.(fq|fastq)$/) ? 'fastq' : 'fasta';
}

my $passed_seq  = $out_prefix.".passed.fna";
my $removed_seq = $out_prefix.".removed.fna";
my $run_dir = getcwd;

# get filter options
# default => filter_ln:min_ln=<MIN>:max_ln=<MAX>:filter_ambig:max_ambig=5:dynamic_trim:min_qual=15:max_lqb=5
unless ($filter_options) {
  if ($format eq 'fasta') {
    my @out = `seq_length_stats.py -i $input_file -t fasta -f | cut -f2`;
    chomp @out;
    my $mean = $out[2];
    my $stdv = $out[3];
    my $min  = int( $mean - (2 * $stdv) );
    my $max  = int( $mean + (2 * $stdv) );
    if ($min < 0) { $min = 0; }
    $filter_options = "filter_ln:min_ln=".$min.":max_ln=".$max.":filter_ambig:max_ambig=5";
  }
  else {
    $filter_options = "dynamic_trim:min_qual=15:max_lqb=5";
  }
}

# skip it
if ($filter_options eq 'skip') {
    if ($format eq 'fasta') {
        PipelineAWE::run_cmd("mv $input_file $passed_seq");
    } else {
        PipelineAWE::run_cmd("seqUtil --fastq2fasta -i $input_file -o $passed_seq");
    }
    PipelineAWE::run_cmd("touch $removed_seq");
}
# do not skip
else {  
    my $cmd_options = "";
    for my $ov (split ":", $filter_options) {
        if ($ov =~ /=/) {
            my ($option, $value) = split "=", $ov;
            $cmd_options .= "-".$option." ".$value." ";
        } else {
            $cmd_options .= "-".$ov." ";
        }
    }
    # run cmd
    PipelineAWE::run_cmd("filter_sequences -i $input_file -format $format -o $passed_seq -r $removed_seq $cmd_options");
}

# file is empty !!!
if (-z $passed_seq) {
    my $user_attr = PipelineAWE::get_userattr();
    my $job_name  = $user_attr->{name};
    my $job_id    = $user_attr->{id};
    my $proj_name = $user_attr->{project_name};
    my $subject   = "MG-RAST Job Failed";
    my $body_txt  = qq(
The annotation job that you submitted for $job_name ($job_id) belonging to study $proj_name has failed.
No sequences passed our QC screening steps. Either your sequences were too short or your pipeline QC settings were to stringent.

This is an automated message.  Please contact help\@mg-rast.org if you have any questions or concerns.
);
    PipelineAWE::post_data($api_url."/user/".$user_attr->{owner}."/notify", $api_key, {'subject' => $subject, 'body' => $body_txt});
    PipelineAWE::logger('error', "pipeline failed, no sequences passed preprocessing");
    # exit failed-permanent
    exit 42;
}

# get stats
my $pass_stats = PipelineAWE::get_seq_stats($passed_seq, 'fasta');
my $fail_stats = PipelineAWE::get_seq_stats($removed_seq, 'fasta');

# output attributes
PipelineAWE::create_attr($passed_seq.'.json', $pass_stats, {data_type => "passed"});
PipelineAWE::create_attr($removed_seq.'.json', $fail_stats, {data_type => "removed"});

# create subset record list
# note: parent and child files in same order
if (($format eq 'fasta') && ($filter_options ne 'skip') and not ($do_not_create_index_files)) {
    PipelineAWE::run_cmd("index_subset_seq.py -p $input_file -c $passed_seq -c $removed_seq -s -m 20 -t $run_dir");
    PipelineAWE::run_cmd("mv $passed_seq.index $passed_seq");
    PipelineAWE::run_cmd("mv $removed_seq.index $removed_seq");
}

exit 0;

sub get_usage {
    return qq "
USAGE: mgrast_preprocess.pl 
          -input=<input fasta or fastq>
          -format=<sequence format> 
          [-out_prefix=<output prefix> 
          -filter_options=<string_filter_options>]
          [-no-shock]
            Don't create subset node files
OUTPUTS: \${out_prefix}.passed.fna and \${out_prefix}.removed.fna"."\n\n";
}
