#!/usr/bin/env perl 

#input: .expand file(s), 
#outputs: ${out_prefix}.$type.summary (for each $type)

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
umask 000;

# options
my %options = (
    md5      => 1,
    ontology => 1,
    function => 1,
    organism => 1,
    source   => 1,
    lca      => 1
);
my @in_expand  = ();
my @in_maps    = ();
my $in_index   = "";
my $in_assemb  = "";
my $out_prefix = "annotate";
my $job_id  = "";
my $ver_db  = 1;
my @type    = ();
my $help    = 0;

my $options = GetOptions (
		"in_expand=s"  => \@in_expand,
		"in_maps=s"    => \@in_maps,
		"in_index=s"   => \$in_index,
		"in_assemb=s"  => \$in_assemb,
		"out_prefix=s" => \$out_prefix,
		"job=s"        => \$job_id,
		"nr_ver=s"     => \$ver_db,
		"type=s"       => \@type,
		"help!"        => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (scalar(@in_expand)==0){
    print STDERR "ERROR: At least one input expand file is required.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (scalar(@in_maps)==0){
    print STDERR "ERROR: At least one input mapping file is required.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (scalar(@type)==0){
    print STDERR "ERROR: At least one summary type is required.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (length($job_id)==0){
    print STDERR "ERROR: A job ID is required.\n";
    print STDERR get_usage();
    exit __LINE__;
}
foreach my $t (@type) {
    if (! exists($options{$t})) {
        print STDERR "ERROR: type $t is invalid.\n";
        print STDERR get_usage();
        exit __LINE__;
    }
    if (($t eq 'md5') && (length($in_index)==0)) {
        print STDERR "ERROR: -in_index is required with type 'md5'.\n";
        print STDERR get_usage();
        exit __LINE__;
    }
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

my $idx_opt = ($in_index && (-s $in_index)) ? "--md5_index $in_index" : "";
my $ass_opt = ($in_assemb && (-s $in_assemb)) ? "--abundance_file $in_assemb" : "";

# summary for each type
foreach my $t (@type) {
    unless (-s $expand_file) {
        PipelineAWE::run_cmd("touch $out_prefix.$t.summary");
    }
    PipelineAWE::run_cmd("expanded_sims2overview_no_sort_required $ass_opt --job $job_id --m5nr-version $ver_db --verbose --option $t $idx_opt --cluster $map_file --expanded_sims_in $expand_file --summary_sims_out $out_prefix.$t.summary");
}

exit(0);

sub get_usage {
    return "USAGE: awe_annotate_summary.pl -in_expand=<one or more input expand files> -in_maps=<one or more input mapping files> -in_index=<md5 index file> -in_assemb=<assembly coverage file> -job=<job identifier> -type=<one or more summary types> [-output_prefix=<output prefix> -nr_ver=<nr db version>]\noutputs: \$${out_prefix}.\$type.summary\n";
}
