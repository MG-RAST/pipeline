#!/usr/bin/env perl 

#input: .fna or .fq 
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

# options
my $input_file = "";
my $out_prefix = "prep";
my $filter_options = "";
my $out_file = "";
my $options = GetOptions ("input=s"   => \$input_file,
			  "out_prefix=s"  => \$out_prefix,
			  "filter_options=s" => \$filter_options,
			  "output=s" => \$out_file, #deprecated
			 );

if (length($input_file)==0){
    print "ERROR: An input file was not specified.\n";
    print_usage();
    exit __LINE__;  #use line number as exit code
}elsif (! -e $input_file){
    print "ERROR: The input genome file [$input_file] does not exist.\n";
    print_usage();
    exit __LINE__;  
}

my ($file,$dir,$ext) = fileparse($input_file, qr/\.[^.]*/);

my $passed_seq = $out_prefix.".passed.fna";

if (length($out_file)>0) { #for compatibility with old pipeline templates (-output is deprecated)
    $passed_seq = $out_file;
}

my $removed_seq = $out_prefix.".removed.fna";

my $cmd_options = "";

# get filter options
if($input_file =~ /\.fn?a$|\.fasta$/i || $input_file =~ /\.(fq|fastq)$/i) {
  for my $ov (split ":", $filter_options) {
    if ($ov =~ /=/) {
      my ($option, $value) = split "=", $ov;
      $cmd_options .= "-".$option." ".$value." ";
    } else {
      $cmd_options .= "-".$ov." ";
    }
  }
  # run cmd
  print "$runcmd -i $input_file -o $passed_seq -r $removed_seq $cmd_options";
  system("$runcmd -i $input_file -o $passed_seq -r $removed_seq $cmd_options");
  if ($? != 0) {print "ERROR: $runcmd returns value $?\n"; exit $?}
}

exit(0);

sub print_usage{
    print "USAGE: awe_preprocess.pl -input=<input fasta or fastq> [-out_prefix=<output prefix> -filter_options=<string_filter_options>]\n";
    print "outputs: \${out_prefix}.passed.fna and \${out_prefix}.removed.fna\n"; 
}

