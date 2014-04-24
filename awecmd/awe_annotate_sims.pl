#!/usr/bin/env perl 

#input: m8 format
#outputs:
#  ${out_prefix}.aa.sims.filter, ${out_prefix}.aa.expand.protein, ${out_prefix}.aa.expand.lca, ${out_prefix}.aa.expand.ontology
#      OR
#  ${out_prefix}.rna.sims.filter, ${out_prefix}.rna.expand.rna, ${out_prefix}.rna.expand.lca

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
umask 000;

# options
my $out_prefix = "annotate_sims";
my $input   = "";
my $memhost = "localhost:11211";
my $memkey  = '_ach';
my $aa      = 0;
my $rna     = 0;
my $help    = 0;
my $options = GetOptions (
        "out_prefix=s" => \$out_prefix,
		"input=s"    => \$input,
		"mem_host=s" => \$memhost,
        "mem_key=s"  => \$memkey,
        "aa!"        => \$aa,
        "rna!"       => \$rna,
		"help!"      => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($input)==0){
    print STDERR "ERROR: An input file was not specified.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (! -e $input){
    print STDERR "ERROR: The input similarity file [$input] does not exist.\n";
    print STDERR get_usage();
    exit __LINE__;
}

my $cmd = "process_sims_by_source_mem --verbose --mem_host $memhost --mem_key $memkey --in_sim $input";
if ($aa) {
    $out_prefix = $out_prefix.".aa";
    $cmd .= " --out_expand $out_prefix.expand.protein --out_ontology $out_prefix.expand.ontology";
} elsif ($rna) {
    $out_prefix = $out_prefix.".rna";
    $cmd .= " --out_rna $out_prefix.expand.rna";
} else {
    print STDERR "ERROR: one of the following modes is required: aa, rna\n";
    print STDERR get_usage();
    exit __LINE__;
}
$cmd .= " --out_filter $out_prefix.sims.filter --out_lca $out_prefix.expand.lca";
PipelineAWE::run_cmd($cmd);

exit(0);

sub get_usage {
    return "USAGE: awe_annotate_sims.pl -input=<input sims> <-aa|-rna> [-output_prefix=<output prefix> -mem_host=<memcache host> -mem_key=<memcache key>]\n".
           "outputs: \${out_prefix}.aa.sims.filter, \${out_prefix}.aa.expand.protein, \${out_prefix}.aa.expand.lca, \${out_prefix}.aa.expand.ontology\n".
           "           OR\n".
           "         \${out_prefix}.rna.sims.filter, \${out_prefix}.rna.expand.rna, \${out_prefix}.rna.expand.lca\n";
}
