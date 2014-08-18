#!/usr/bin/env perl 

#input: .fna, .fasta, .fq, or .fastq 
#outputs: output.stats.txt

use strict;
use warnings;
no warnings('once');

use Getopt::Long;
use File::Copy;
use File::Basename;
use POSIX qw(strftime);
umask 000;

my $runcmd   = "seq_length_stats.py";

# options
my $input_file = "";
my $output_file = "";
my $help = "";
my $options = GetOptions ("input=s"   => \$input_file,
			  "output=s"  => \$output_file,
			  "help!" => \$help
			 );

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
} elsif ($input_file !~ /\.(fna|fasta|fq|fastq)$/i) {
    print STDERR "ERROR: The input sequence file must be fasta or fastq format.\n";
    print_usage();
    exit __LINE__;
}

if (len($output_file) == 0) {
    $output_file = "$input_file.stats.txt";
}

if ( $input_file =~ /\.(fna|fasta)$/i ) {
    print "$runcmd -i $input_file -o $output_file -t fasta";
    run_cmd("$runcmd -i $input_file -o $output_file -t fasta");
} elsif ( $input_file =~ /\.(fq|fastq)$/i ) {
    print "$runcmd -i $input_file -o $output_file -t fastq";
    run_cmd("$runcmd -i $input_file -o $output_file -t fastq");
} else {
    print STDERR "ERROR: The input sequence file must be fasta or fastq format.\n";
    print_usage();
    exit __LINE__;
}

exit(0);

sub print_usage{
    print "USAGE: awe_seq_length_stats.pl -input=<input fasta or fastq> [-output=<output filename>]\n";
    print "outputs: <input>.stats.txt\n"; 
}

sub run_cmd{
    my ($cmd) = @_;
    my $run = (split(/ /, $cmd))[0];
    system($cmd);
    if ($? != 0) {
        print "ERROR: $run returns value $?\n";
        exit $?;
    }
}
