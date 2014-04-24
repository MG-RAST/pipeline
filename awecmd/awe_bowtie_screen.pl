#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
umask 000;

my $index_ids = {
    'a_thaliana'     => 201,
    'b_taurus'       => 202,
    'd_melanogaster' => 203,
    'e_coli'         => 204,
    'h_sapiens'      => 205,
    'm_musculus'     => 206,
    's_scrofa'       => 207,
};

# options
my $fasta  = "";
my $output = "";
my $run_bowtie = 1;
my $index   = "";
my $proc    = 8;
my $help    = 0;
my $options = GetOptions (
        "input=s"  => \$fasta,
		"output=s" => \$output,
		"index=s"  => \$index,
		"proc=i"   => \$proc,
		"bowtie=i" => \$run_bowtie,
		"help!"    => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($fasta)==0){
    print STDERR "ERROR: An input file was not specified.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (length($output)==0){
    print STDERR "ERROR: An output file was not specified.\n";
    print STDERR get_usage();
    exit __LINE__;
}elsif (! -e $fasta){
    print STDERR "ERROR: The input sequence file [$fasta] does not exist.\n";
    print STDERR get_usage();
    exit __LINE__;
}

if ($run_bowtie == 0) {
    PipelineAWE::run_cmd("cp $fasta $output");
    exit(0);
}

# check indexes
my @indexes = split(/,/, $index);
for my $i (@indexes) {
    unless ( defined $index_ids->{$i} ) {
        print STDERR "ERROR: undefined index name: $i\n";
        exit __LINE__
    }
}

my $index_dir = ".";
if ($ENV{'REFDBPATH'}) {
    $index_dir = "$ENV{'REFDBPATH'}";
}

my $input_file = $fasta;
for my $index_name (@indexes) {
    my $unaligned = $index_ids->{$index_name}.".".$index_name.".passed.fna";
    PipelineAWE::run_cmd("bowtie2 -f --reorder -p $proc --un $unaligned -x $index_dir/$index_name -U $input_file > /dev/null", 1);
    $input_file = $unaligned;
}
PipelineAWE::run_cmd("mv $input_file $output");

exit(0);

sub get_usage {
    return "USAGE: awe_bowtie_screen.pl -input=<input fasta> -output=<output fasta> -index=<bowtie indexes separated by ,> [-proc=<number of threads, default: 8>]\n";
}
