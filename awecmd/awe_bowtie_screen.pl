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
    'r_norvegicus'   => 208
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
    exit 1;
}elsif (length($output)==0){
    print STDERR "ERROR: An output file was not specified.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! -e $fasta){
    print STDERR "ERROR: The input sequence file [$fasta] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}

# skip it
if ($run_bowtie == 0) {
    PipelineAWE::run_cmd("mv $fasta $output");
}
# run it
else {
    # check indexes
    my @indexes = split(/,/, $index);
    if (scalar(@indexes) == 0) {
        print STDERR "ERROR: missing index\n";
        exit 1;
    }
    for my $i (@indexes) {
        unless ( defined $index_ids->{$i} ) {
            print STDERR "ERROR: undefined index name: $i\n";
            exit 1;
        }
    }

    # get index dir
    my $index_dir = ".";
    if ($ENV{'REFDBPATH'}) {
        $index_dir = "$ENV{'REFDBPATH'}";
    }

    # truncate input to 1000 bp
    my $input_file = $fasta.'.trunc';
    PipelineAWE::run_cmd("seqUtil --truncateuniqueid 1000 -i $fasta -o $input_file");

    # run bowtie2
    my $tmp_input_var = $input_file;
    for my $index_name (@indexes) {
        my $unaligned = $index_ids->{$index_name}.".".$index_name.".passed.fna";
        # 'reorder' option outputs sequences in same order as input file
        PipelineAWE::run_cmd("bowtie2 -f --reorder -p $proc --un $unaligned -x $index_dir/$index_name -U $tmp_input_var > /dev/null", 1);
        $tmp_input_var = $unaligned;
    }
    PipelineAWE::run_cmd("mv $tmp_input_var $output");

    # create subset record list
    # note: parent and child files in same order
    PipelineAWE::run_cmd("index_subset_seq.py -p $input_file -c $output -s -m 20");
    PipelineAWE::run_cmd("mv $output.index $output");
}

exit 0;

sub get_usage {
    return "USAGE: awe_bowtie_screen.pl -input=<input fasta> -output=<output fasta> -index=<bowtie indexes separated by ,> [-proc=<number of threads, default: 8>]\n";
}
