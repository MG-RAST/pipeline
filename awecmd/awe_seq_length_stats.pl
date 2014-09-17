#!/usr/bin/env perl 

#input: .fna, .fasta, .fq, or .fastq 
#outputs: output.stats.txt

use strict;
use warnings;
no warnings('once');

use Getopt::Long;
use File::Copy;
use File::Basename;
use File::Slurp;
use JSON;
use POSIX qw(strftime);
umask 000;

my $runcmd   = "seq_length_stats.py";

# options
my $input_file = "";
my $input_json_file = "";
my $output_file = "";
my $output_json_file = "";
my $type = "fasta";
my $help = "";
my $options = GetOptions ("input=s"   => \$input_file,
                          "input_json=s" => \$input_json_file,
                          "output=s" => \$output_file,
                          "output_json=s"  => \$output_json_file,
                          "type=s" => \$type,
                          "help!" => \$help
                         );

# Validate input file path.
if ($help) {
    print_usage();
    exit 0;
} elsif (length($input_file)==0) {
    print STDERR "ERROR: An input file was not specified.\n";
    print_usage();
    exit __LINE__;  #use line number as exit code
} elsif (! -e $input_file) {
    print STDERR "ERROR: The input sequence file [$input_file] does not exist.\n";
    print_usage();
    exit __LINE__;
}

if ($type ne 'fasta' && $type ne 'fastq') {
    print STDERR "ERROR: The file type must be fasta or fastq format (default is fasta).\n";
    print_usage();
    exit __LINE__;
}

# Validate other input and output file paths.
my $data;
if (length($input_json_file) != 0) {
    unless (-e $input_json_file) {
        print STDERR "ERROR: The input_json file [$input_json_file] does not exist.\n";
        print_usage();
        exit __LINE__;
    }
    my $text = read_file( $input_json_file ) ;
    $data = decode_json($text);
}

if ($output_file eq "") {
    $output_file = "$input_file.stats.txt";
}

if (-e $output_file) {
    print STDERR "ERROR: The output file path [$output_file] already exists.\n";
    print_usage();
    exit __LINE__;
}

if ($output_json_file eq "") {
    $output_json_file = "$input_file.out.json";
}

if (-e $output_json_file) {
    print STDERR "ERROR: The output_json file path [$output_json_file] already exists.\n";
    print_usage();
    exit __LINE__;
}

# Run sequence stats analysis
if ( $type eq 'fastq' ) {
    print "$runcmd -i $input_file -o $output_file -t fastq";
    run_cmd("$runcmd -i $input_file -o $output_file -t fastq");
} else {
    print "$runcmd -i $input_file -o $output_file -t fasta";
    run_cmd("$runcmd -i $input_file -o $output_file -t fasta");
}

# Create/replace stats_info section
$data->{stats_info} = {};
open IN, $output_file || die "Cannot open $output_file for reading.\n";
while(my $line=<IN>) {
    chomp $line;
    my @arr = split(/\t/, $line);
    if(@arr == 2) {
        $data->{stats_info}->{$arr[0]} = $arr[1];
    }
}
close IN;

open OUT, ">$output_json_file" || die "Cannot open $output_json_file for writing.\n";
print OUT encode_json($data);
close OUT;

exit(0);

sub print_usage {
    print "USAGE: awe_seq_length_stats.pl -input=<input fasta or fastq> [-input_json=<attr_filename>, -output=<stats_text_file>, -output_json=<attr_filename>, -type=<fasta or fastq (default is fasta)>]\n";
}

sub run_cmd {
    my ($cmd) = @_;
    my $run = (split(/ /, $cmd))[0];
    system($cmd);
    if ($? != 0) {
        print "ERROR: $run returns value $?\n";
        exit $?;
    }
}
