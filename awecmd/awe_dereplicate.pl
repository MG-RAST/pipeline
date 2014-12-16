#!/usr/bin/env perl

#input: fasta
#outputs: ${out_prefix}.passed.fna, ${out_prefix}.passed.fna

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use Cwd;
umask 000;

# options
my $input = "";
my $out_prefix  = "derep";
my $prefix_size = 50;
my $memory    = 16;
my $run_derep = 1;
my $help    = 0;
my $options = GetOptions (
        "input=s"         => \$input,
		"out_prefix=s"    => \$out_prefix,
		"prefix_length=i" => \$prefix_size,
		"memory=i"        => \$memory,
		"dereplicate=i"   => \$run_derep,
		"help!"           => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($input)==0){
    print STDERR "ERROR: An input file was not specified.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! -e $input){
    print STDERR "ERROR: The input sequence file [$input] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}

my $passed_seq  = $out_prefix.".passed.fna";
my $removed_seq = $out_prefix.".removed.fna";
my $run_dir = getcwd;

# skip it
if ($run_derep == 0) {
    PipelineAWE::run_cmd("mv $input $passed_seq");
    PipelineAWE::run_cmd("touch $removed_seq");
} 
# run it
else {
    PipelineAWE::run_cmd("dereplication.py -l $prefix_size -m $memory -d $run_dir $input $out_prefix");
}

# get stats
my $pass_stats = PipelineAWE::get_seq_stats($passed_seq, 'fasta');
my $fail_stats = PipelineAWE::get_seq_stats($removed_seq, 'fasta');

# output attributes
PipelineAWE::create_attr($passed_seq.'.json', $pass_stats, {data_type => "passed"});
PipelineAWE::create_attr($removed_seq.'.json', $fail_stats, {data_type => "removed"});

# create subset record list
# note: parent and child files NOT in same order
if ($run_derep != 0) {
    PipelineAWE::run_cmd("index_subset_seq.py -p $input -c $passed_seq -c $removed_seq -m $memory -t $run_dir");
    PipelineAWE::run_cmd("mv $passed_seq.index $passed_seq");
    PipelineAWE::run_cmd("mv $removed_seq.index $removed_seq");
}

exit 0;

sub get_usage {
    return "USAGE: awe_dereplicate.pl -input=<input fasta> [-out_prefix=<output prefix> --prefix_length=<INT prefix length>]\n".
           "outputs: \${out_prefix}.passed.fna and \${out_prefix}.removed.fna\n";
}
