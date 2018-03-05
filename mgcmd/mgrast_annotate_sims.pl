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
my $input      = "";
my $scgs       = "";
my $achver     = "1";
my $ann_file   = "/mnt/awe/data/predata/m5nr_v1.bdb";
my $aa         = 0;
my $rna        = 0;
my $help       = 0;

my $options    = GetOptions (
        "out_prefix=s" => \$out_prefix,
		"input=s"      => \$input,
        "scgs=s"       => \$scgs,
		"ach_ver=s"    => \$achver,
		"ann_file=s"   => \$ann_file,
        "aa!"          => \$aa,
        "rna!"         => \$rna,
		"help!"        => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($input)==0){
    PipelineAWE::logger('error', "input file was not specified");
    exit 1;
}elsif (! -e $input){
    PipelineAWE::logger('error', "input similarity file [$input] does not exist");
    exit 1;
}

my @out_files = ();
my $cmd = "sims_annotate.pl --verbose --in_sim $input --ann_file $ann_file";

my $type = "";
if ($aa) {
    $type = 'aa';
    $cmd .= " --format protein --out_expand $out_prefix.$type.expand.protein";
    if ($scgs) {
        $cmd .= " --in_scg $scgs";
    }
    push @out_files, "$out_prefix.$type.expand.protein";
} elsif ($rna) {
    $type = 'rna';
    $cmd .= " --format rna --out_expand $out_prefix.$type.expand.rna";
    push @out_files, "$out_prefix.$type.expand.rna";
} else {
    PipelineAWE::logger('error', "one of the following modes is required: --aa, --rna");
    exit 1;
}
$cmd .= " --out_filter $out_prefix.$type.sims.filter --out_lca $out_prefix.$type.expand.lca";
push @out_files, ("$out_prefix.$type.sims.filter", "$out_prefix.$type.expand.lca");

# run it
if (-s $input) {
    PipelineAWE::run_cmd($cmd);
} else {
    # empty input file
    foreach my $out (@out_files) {
        PipelineAWE::run_cmd("touch $out");
    }
}

# output attributes
foreach my $out (@out_files) {
    if ($out =~ /filter$/) {
        my $fstat = `cut -f1 $out | uniq | wc -l`;
        chomp $fstat;
        PipelineAWE::create_attr(
            $out.'.json',
            {'sequence_count_sims_'.$type => $fstat},
            {sim_type => "filter", data_type => "similarity", file_format => "blast m8"}
        );
    } else {
        my @parts = split(/\./, $out);
        PipelineAWE::create_attr(
            $out.'.json',
            undef,
            {sim_type => "expand", data_type => $parts[-1], file_format => "text"}
        );
    }
}

exit 0;

sub get_usage {
    return "USAGE: mgrast_annotate_sims.pl -input=<input sims> <-aa|-rna> -ann_file <m5nr annotations, .bdb> [-out_prefix=<output prefix> -ach_ver=<ach db ver>]\n".
           "outputs: \${out_prefix}.aa.sims.filter, \${out_prefix}.aa.expand.lca, [\${out_prefix}.aa.expand.protein or \${out_prefix}.rna.expand.rna]\n";
}
