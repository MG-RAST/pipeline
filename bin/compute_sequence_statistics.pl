#!/usr/bin/env perl

use warnings;
use strict;
use Getopt::Long;

my ($file, $dir, $file_format, $tmp_dir, $help);

GetOptions( 'help!'  => \$help,
	    'file=s' => \$file,
	    'dir=s'  => \$dir,
	    'file_format=s' => \$file_format,
	    'tmp_dir:s'     => \$tmp_dir );

my $usage = "Usage: compute_sequence_statistics.pl --file <sequence file> --dir <dir path> --file_format <fasta|fastq>\n";
if ($help) {
  print STDOUT $usage;
  exit(0);
}
unless ($file && $dir && $file_format) {
  print STDERR "[error] ".$usage;
  exit(1);
}
unless (-d $dir) {
  print STDERR "[error] dir: $dir does not exist\n";
  exit(1);
}
$tmp_dir = ($tmp_dir && (-d $tmp_dir)) ? $tmp_dir : $dir."/.tmp";

### report keys:
# bp_count, sequence_count, length_max, id_length_max, length_min, id_length_min, file_size,
# average_length, standard_deviation_length, average_gc_content, standard_deviation_gc_content,
# average_gc_ratio, standard_deviation_gc_ratio, ambig_char_count, ambig_sequence_count, average_ambig_chars

my $filetype = ($file_format eq 'fastq') ? " -t fastq" : "";

my $report = {};
my @error  = ();
my @stats  = `seq_length_stats.py -i '$dir/$file'$filetype -s 2>&1`;
chomp @stats;

foreach my $line (@stats) {
  if ($line =~ /^\[error\]\s+(.*)/) {
    push @error, "Error\t".$1;
  } else {
    my ($key, $value) = split(/\t/, $line);
    $report->{$key} = $value;
  }
}
if ((@error == 0) && (($report->{sequence_count} eq "0") || ($report->{bp_count} eq "0"))) {
  push @error, "Error\tFile contains no sequences";
}

if (@error == 0) {
  # tech guess
  my $header  = `head -1 '$dir/$file'`;
  my $options = '-s '.$report->{sequence_count}.' -a '.$report->{average_length}.' -d '.$report->{standard_deviation_length}.' -m '.$report->{length_max};
  my $method  = `tech_guess -f '$header' $options 2>&1`;
  chomp $method;

  if ($method =~ /^\[error\]\s+(.*)/) {
    push @error, "Error\t".$1;
  } else {
    push @stats, "sequencing_method_guess\t$method";
  }

  # count unique ids
  my $unique_ids = 0;
  if ($file_format eq 'fasta') {
    $unique_ids = `grep '>' $dir/$file | cut -f1 -d' ' | sort -T $tmp_dir -u | wc -l 2>&1`;
    chomp $unique_ids;
  }
  elsif ($file_format eq 'fastq') {
    $unique_ids = `awk '0 == (NR + 3) % 4' $dir/$file | cut -f1 -d' ' | sort -T $tmp_dir -u | wc -l 2>&1`;
    chomp $unique_ids;
  }
  
  my $unique_id_num = int($unique_ids);
  if (($unique_ids ne $unique_id_num) || ($unique_ids == 0)) {
    push @error, "Error\tUnable to count unique ids";
  } else {
    push @stats, "unique_id_count\t$unique_ids";
  }
}

# write results
open(FH, ">>$dir/$file.stats_info") or die "could not open stats file for $dir/$file.stats_info: $!";
if (@error > 0) {
  foreach my $line (@error) {
    print FH $line."\n";		
  }
} else {
  foreach my $line (@stats) {
    print FH $line."\n";		
  }
}
close FH;
