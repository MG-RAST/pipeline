#!/usr/bin/env perl

#input: fasta
#outputs:  ${out_prefix}.aa${pid}.faa, ${out_prefix}.aa${pid}.mapping
#            OR
#          ${out_prefix}.rna${pid}.fna or ${out_prefix}.rna${pid}.mapping
#            OR
#          ${out_prefix}.dna${pid}.fna or ${out_prefix}.dna${pid}.mapping

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use Cwd;
umask 000;

# options
my $out_prefix = "cluster";
my $fasta   = "";
my $pid     = 90;
my $mem     = 16;
my $aa      = 0;
my $rna     = 0;
my $dna     = 0;
my $help    = 0;
my $options = GetOptions (
        "out_prefix=s" => \$out_prefix,
        "input=s" => \$fasta,
		"pid=i"   => \$pid,
		"mem=i"   => \$mem,
		"aa!"     => \$aa,
        "rna!"    => \$rna,
        "dna!"    => \$dna,
        "help!"   => \$help
);

if ($help){
    print_usage();
    exit 0;
}elsif (length($fasta)==0){
    print "ERROR: An input file was not specified.\n";
    print_usage();
    exit __LINE__;
}elsif (! -e $fasta){
    print "ERROR: The input sequence file [$fasta] does not exist.\n";
    print_usage();
    exit __LINE__;
}elsif ((! $pid) || ($pid < 40)){
    print "ERROR: The percent identity must be greater than 50\n";
    print_usage();
    exit __LINE__;
}

my ($cmd, $word, $code, $output);
if ($aa) {
    ($cmd, $word, $code, $output) = ("cd-hit", word_length("aa", $pid), "aa", $out_prefix.".aa".$pid.".faa");
} else {
    $code = $rna ? 'rna' : 'dna';
    ($cmd, $word, $output) = ("cd-hit-est", word_length($code, $pid), $out_prefix.".".$code.$pid.".fna");
}
my $memory = $mem * 1024;

print "$cmd -n $word -d 0 -T 0 -M $memory -c 0.$pid -i $fasta -o $output\n";
PipelineAWE::run_cmd("$cmd -n $word -d 0 -T 0 -M $memory -c 0.$pid -i $fasta -o $output");

# TODO
# turn $output.clstr into $out_prefix.".".$code.$pid.".mapping"

exit(0);

sub print_usage {
    print "USAGE: awe_cluster.pl -input=<input fasta> <-aa|-rna> -pid=<percentage of identification, default 90> [-out_prefix=<output prefix> -mem=<memory usage in GB, default is 16>]\n";
}

# determine optimal word length for clustering
sub word_length {
    my ($type, $pid) = @_;
    
    if ($type eq 'aa') {
        if ($pid > 70) {
            return 5;
        } elsif ($pid > 60) {
            return 4;
        } elsif ($pid > 50) {
            return 3;
        } else {
            return 2;
        }
    } else {
        if ($pid > 98) {
            return 10;
        } elsif ($pid > 95) {
            return 9;
        } elsif ($pid > 90) {
            return 8;
        } elsif ($pid > 88) {
            return 7;
        } elsif ($pid > 85) {
            return 6;
        } elsif ($pid > 80) {
            return 5;
        } elsif ($pid > 75) {
            return 4;
        } elsif ($pid > 60) {
            return 3;
        } else {
            return 2;
        }
    }
}

