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
my $achver  = "1";
my $aa      = 0;
my $rna     = 0;
my $help    = 0;
my $options = GetOptions (
        "out_prefix=s" => \$out_prefix,
		"input=s"    => \$input,
		"ach_ver=s"  => \$achver,
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
    exit 1;
}elsif (! -e $input){
    print STDERR "ERROR: The input similarity file [$input] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}

# get db variables from enviroment
my $achhost = $ENV{'ACH_MONGO_HOST'} || undef;
my $achname = $ENV{'ACH_MONGO_NAME'} || undef;
my $achuser = $ENV{'ACH_MONGO_USER'} || undef;
my $achpass = $ENV{'ACH_MONGO_PASS'} || undef;
unless ( defined($achhost) && defined($achname) && defined($achuser) && defined($achpass) ) {
    print STDERR "ERROR: missing ACH mongodb ENV variables.\n";
    print STDERR get_usage();
    exit 1;
}
my $achopts = "--ach_host ".$achhost." --ach_name ".$achname." --ach_user ".$achuser." --ach_pass ".$achpass." --ach_ver ".$achver;

my @out_files = ();
my $cmd  = "process_sims_by_source_mem --verbose $achopts --in_sim $input";
my $type = "";

if ($aa) {
    $type = 'aa';
    $cmd .= " --out_expand $out_prefix.$type.expand.protein --out_ontology $out_prefix.$type.expand.ontology";
    push @out_files, ("$out_prefix.$type.expand.protein", "$out_prefix.$type.expand.ontology");
} elsif ($rna) {
    $type = 'rna';
    $cmd .= " --out_rna $out_prefix.$type.expand.rna";
    push @out_files, "$out_prefix.$type.expand.rna";
} else {
    print STDERR "ERROR: one of the following modes is required: aa, rna\n";
    print STDERR get_usage();
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
    } elsif ($out =~ /ontology$/) {
        my $ostat = `cut -f2 $out | uniq | wc -l`;
        chomp $ostat;
        PipelineAWE::create_attr(
            $out.'.json',
            {sequence_count_ontology => $ostat},
            {sim_type => "expand", data_type => 'ontology', file_format => "text"}
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
    return "USAGE: awe_annotate_sims.pl -input=<input sims> <-aa|-rna> [-out_prefix=<output prefix> -ach_host=<ach mongodb host> -ach_ver=<ach db ver>]\n".
           "outputs: \${out_prefix}.aa.sims.filter, \${out_prefix}.aa.expand.protein, \${out_prefix}.aa.expand.lca, \${out_prefix}.aa.expand.ontology\n".
           "           OR\n".
           "         \${out_prefix}.rna.sims.filter, \${out_prefix}.rna.expand.rna, \${out_prefix}.rna.expand.lca\n";
}
