#!/usr/bin/env perl 

#input: .fna or .fastq 
#outputs:  ${out_prefix}.passed.fna and ${out_prefix}.removed.fna

use strict;
use warnings;
no warnings('once');

use Getopt::Long;
use File::Copy;
use File::Basename;
use POSIX qw(strftime);
umask 000;

my $runcmd   = "filter_sequences";
my $qc_cmd   = "awe_qc.pl";

# options
my $input_file = "";
my $assembled = 0;
my $out_prefix_prep = "prep";
my $out_prefix_qc = "qc";
my $filter_options = "";
my $out_file = "";
my $help = "";
my $options = GetOptions ("input=s"   => \$input_file,
                          "assembled=i" => \$assembled,
			  "out_prefix_prep=s" => \$out_prefix_prep,
			  "filter_options=s" => \$filter_options,
			  "output=s" => \$out_file, #deprecated
			  "out_prefix_qc=s"  => \$out_prefix_qc,
			  "help!" => \$help
			 );

if ($help){
    print_usage();
    exit 0;
}elsif (length($input_file)==0){
    print "ERROR: An input file was not specified.\n";
    print_usage();
    exit __LINE__;  #use line number as exit code
}elsif (! -e $input_file){
    print "ERROR: The input genome file [$input_file] does not exist.\n";
    print_usage();
    exit __LINE__;  
}elsif ($input_file !~ /\.(fna|fasta|fq|fastq)$/i) {
    print "ERROR: The input sequence file must be fasta or fastq format.\n";
    print_usage();
    exit __LINE__;
}

my $passed_seq = $out_prefix_prep.".passed.fna";
my $removed_seq = $out_prefix_prep.".removed.fna";
if (length($out_file)>0) { #for compatibility with old pipeline templates (-output is deprecated)
    $passed_seq = $out_file;
}

# get filter options
# default => filter_ln:min_ln=<MIN>:max_ln=<MAX>:filter_ambig:max_ambig=5:dynamic_trim:min_qual=15:max_lqb=5
unless ($filter_options) {
  if ( $input_file =~ /\.(fna|fasta)$/i ) {
    my @out = `seq_length_stats.py -i $input_file -t fasta -f | cut -f2`;
    chomp @out;
    my $mean = $out[2];
    my $stdv = $out[3];
    my $min  = int( $mean - (2 * $stdv) );
    my $max  = int( $mean + (2 * $stdv) );
    if ($min < 0) { $min = 0; }
    $filter_options = "filter_ln:min_ln=".$min.":max_ln=".$max.":filter_ambig:max_ambig=5";
  }
  elsif ( $input_file =~ /\.(fq|fastq)$/i ) {
    $filter_options = "dynamic_trim:min_qual=15:max_lqb=5";
  }
  else {
    $filter_options = "skip";
  }
}

# do not skip
unless ( $filter_options =~ /^skip$/i ) {
  my $cmd_options = "";
  for my $ov (split ":", $filter_options) {
    if ($ov =~ /=/) {
      my ($option, $value) = split "=", $ov;
      $cmd_options .= "-".$option." ".$value." ";
    } elsif($ov ne "dynamic_trim") {
      $cmd_options .= "-".$ov." ";
    }
  }

  # run cmd
  print "$runcmd -i $input_file -o $passed_seq -r $removed_seq $cmd_options\n";
  run_cmd("$runcmd -i $input_file -o $passed_seq -r $removed_seq $cmd_options");
}
# skip it
else {
  if ( $input_file =~ /\.(fna|fasta)$/i ) {
    run_cmd("cp $input_file $passed_seq");
  } elsif ( $input_file =~ /\.(fq|fastq)$/i ) {
    run_cmd("seqUtil --fastq2fasta -i $input_file -o $passed_seq");
  }
  run_cmd("touch $removed_seq");
}

# run qc
print "$qc_cmd -seqs=$input_file -out_prefix=$out_prefix_qc -assembled=$assembled\n";
run_cmd("$qc_cmd -seqs=$input_file -out_prefix=$out_prefix_qc -assembled=$assembled");

exit(0);

sub print_usage{
    print "USAGE: awe_preprocess_qc.pl -input=<input fasta or fastq> [-assembled=<0 or 1, default 0> -out_prefix_qc=<output prefix for qc> -out_prefix_prep=<output prefix for preproces> -filter_options=<string_filter_options>]\n";
    print "outputs: \${out_prefix_prep}.passed.fna, \${out_prefix_prep}.removed.fna and 5 qc stats files\n"; 
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
