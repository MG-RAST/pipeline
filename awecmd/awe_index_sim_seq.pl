#!/usr/bin/env perl 

#input: m8 format
#outputs: $output and ${output}.index

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use Cwd;
umask 000;

# options
my @in_sims = ();
my @in_maps = ();
my $in_seq  = "";
my $output  = "";
my $memory  = 16;
my $memhost = "localhost:11211";
my $memkey  = '_ach';
my $help    = 0;
my $options = GetOptions (
		"in_sims=s"  => \@in_sims,
		"in_maps=s"  => \@in_maps,
		"in_seq=s"   => \$in_seq,
		"output=s"   => \$output,
		"memory=i"   => \$memory,
		"mem_host=s" => \$memhost,
        "mem_key=s"  => \$memkey,
		"help!"      => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (scalar(@in_sims)==0){
    print STDERR "ERROR: At least one input similarity file is required.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (scalar(@in_maps)==0){
    print STDERR "ERROR: At least one input mapping file is required.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (length($in_seq)==0){
    print STDERR "ERROR: An input sequence file was not specified.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (length($output)==0){
    print STDERR "ERROR: An output file was not specified.\n";
    print STDERR get_usage();
    exit __LINE__;
}

my $sim_file = "sims.filter.".time();
if (@in_sims > 1) {
    PipelineAWE::run_cmd("cat ".join(" ", @in_sims)." > ".$sim_file, 1);
    PipelineAWE::run_cmd("rm ".join(" ", @in_sims));
} else {
    PipelineAWE::run_cmd("mv ".$in_sims[0]." ".$sim_file);
}

my $map_file = "mapping.".time();
if (@in_maps > 1) {
    PipelineAWE::run_cmd("cat ".join(" ", @in_maps)." > ".$map_file, 1);
    PipelineAWE::run_cmd("rm ".join(" ", @in_maps));
} else {
    PipelineAWE::run_cmd("mv ".$in_maps[0]." ".$map_file);
}

my $run_dir = getcwd;

# TODO - all the child scripts that need to run

exit(0);

sub get_usage {
    return "USAGE: awe_index_sim_seq.pl [-memory=<memory usage in GB, default is 16> -mem_host=<memcache host> -mem_key=<memcache key>]\n";
}
