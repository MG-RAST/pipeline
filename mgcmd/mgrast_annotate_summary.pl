#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
umask 000;

# options
my %types = (
    md5      => 1,
    ontology => 1,
    function => 1,
    organism => 1,
    source   => 1,
    lca      => 1
);
my @in_expand = ();
my @in_maps   = ();
my $in_index  = "";
my $in_assemb = "";
my $output  = "";
my $type    = "";
my $help    = 0;
my $options = GetOptions (
		"in_expand=s"  => \@in_expand,
		"in_maps=s"    => \@in_maps,
		"in_index=s"   => \$in_index,
		"in_assemb=s"  => \$in_assemb,
		"output=s"     => \$output,
		"type=s"       => \$type,
		"help!"        => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (scalar(@in_expand)==0){
    PipelineAWE::logger('error', "at least one input expand file is required");
    exit 1;
}elsif (scalar(@in_maps)==0){
    PipelineAWE::logger('error', "at least one input expand file is required");
    exit 1;
}elsif (length($type)==0){
    PipelineAWE::logger('error', "summary type is required");
    exit 1;
}elsif (! exists($types{$type})){
    PipelineAWE::logger('error', "type $type is invalid");
    exit 1;
}elsif (($type eq 'md5') && (length($in_index)==0)){
    PipelineAWE::logger('error', "--in_index is required with type 'md5'");
    exit 1;
}elsif (length($output)==0){
    PipelineAWE::logger('error', "output file was not specified");
    exit 1;
}

# temp files
my $expand_file = "expand.".time();
my $map_file = "mapping.".time();

# cat file sets
if (@in_expand > 1) {
    PipelineAWE::run_cmd("cat ".join(" ", @in_expand)." > ".$expand_file, 1);
    PipelineAWE::run_cmd("rm ".join(" ", @in_expand));
} else {
    PipelineAWE::run_cmd("mv ".$in_expand[0]." ".$expand_file);
}
if (@in_maps > 1) {
    PipelineAWE::run_cmd("cat ".join(" ", @in_maps)." > ".$map_file, 1);
    PipelineAWE::run_cmd("rm ".join(" ", @in_maps));
} else {
    PipelineAWE::run_cmd("mv ".$in_maps[0]." ".$map_file);
}

# summary for type
my $cmd = "expanded_sims2overview_no_sort_required_less_memory_used.py -i $expand_file -o $output -t $type --cluster $map_file";
if ($in_index && (-s $in_index)) {
    $cmd .= " --md5_index $in_index";
}
if ($in_assemb && (-s $in_assemb)) {
    $cmd .= " --coverage $in_assemb";
}

# run it
if (-s $expand_file) {
    PipelineAWE::run_cmd($cmd);
} else {
    # empty input file
    PipelineAWE::run_cmd("touch $output");
}

# throw error if empty md5s
if (($type eq 'md5') && (! -s $output)) {
    PipelineAWE::logger('error', "input files ".join(", ", @in_expand)." produced empty output $output");
    exit 1;
}

if ($type eq 'source') {
    my $sdata = get_source_stats($output);
    PipelineAWE::print_json($output.'.temp', $sdata);
    PipelineAWE::run_cmd("mv $output.temp $output");
}

exit 0;

sub get_usage {
    return "USAGE: mgrast_annotate_summary.pl -in_expand=<one or more input expand files> -in_maps=<one or more input mapping files> -in_index=<md5 index file> -in_assemb=<assembly coverage file> -output=<output summary file> -type=<summary types>\n";
}

sub get_source_stats {
    my ($file) = @_;
    
    my $data = {};
    unless ($file && (-s $file)) { return $data; }
    
    open(FILE, "<$file") || return $data;
    while (my $line = <FILE>) {
        chomp $line;
        my @parts  = split(/\t/, $line);
        my $source = shift @parts;
        if (@parts == 10) {
            $data->{$source}->{evalue}  = [ @parts[0..4] ];
            $data->{$source}->{identity} = [ @parts[5..9] ];
        }
    }
    close(FILE);
    
    return $data;
    # source => type => [#, #, #, #, #]
}
