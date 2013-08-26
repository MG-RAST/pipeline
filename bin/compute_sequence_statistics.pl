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

my $usage = "Usage: compute_sequence_statistics.pl --file <sequence file> --dir <dir path> --file_format <fasta|fastq> [--tmp_dir <tmp dir path>]\n";
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
my $file_md5 = '';

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
  # sequence content guess
  my $seq_content = "";
  if($file_format eq 'fastq') {
    $seq_content = 'DNA';
  } else {
    my $max_chars = 10000;
    my $seq = '';
    my $line;
    open(TMP, "<$dir/$file") or die "could not open file '$dir/$file': $!";
    while ( defined($line = <TMP>) ) {
      chomp $line;
      if ( $line =~ /^\s*$/ or $line =~ /^>/ ) {
        next;
      } else {
        $seq .= $line;
      }

      last if (length($seq) >= $max_chars);
    }
    close(TMP);

    $seq =~ tr/A-Z/a-z/;

    my %char_count;
    foreach my $char ( split('', $seq) ) {
        $char_count{$char}++;
    }

    $char_count{a} ||= 0;
    $char_count{c} ||= 0;
    $char_count{g} ||= 0;
    $char_count{t} ||= 0;
    $char_count{n} ||= 0;
    $char_count{x} ||= 0;
    $char_count{'-'} ||= 0;

    # find fraction of a,c,g,t characters from total, not counting '-', 'N', 'X'
    my $bp_char = $char_count{a} + $char_count{c} + $char_count{g} + $char_count{t};
    my $n_char  = length($seq) - $char_count{n} - $char_count{x} - $char_count{'-'};
    my $fraction = $n_char ? $bp_char/$n_char : 0;

    # A high fraction of dashes could indicate a sequence alignment file
    my $dash_fraction = $char_count{'-'}/length($seq);

    if ( $fraction <= 0.6 ) {
        $seq_content = "protein";
    } elsif( $dash_fraction >= 0.05 ) {
        $seq_content = "sequence alignment";
    } else {
        $seq_content = "DNA";
    }
  }
  push @stats, "sequence_content\t$seq_content";

  # md5sum
  $file_md5 = `md5sum '$dir/$file'`;
  chomp $file_md5;
  $file_md5 =~ s/^(\S+).*/$1/;
  push @stats, "file_checksum\t$file_md5";

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
    $unique_ids = `grep '>' $dir/$file | cut -f1 -d' ' | sort -T $tmp_dir -S 2G -u | wc -l 2>&1`;
    chomp $unique_ids;
  }
  elsif ($file_format eq 'fastq') {
    $unique_ids = `awk '0 == (NR + 3) % 4' $dir/$file | cut -f1 -d' ' | sort -T $tmp_dir -S 2G -u | wc -l 2>&1`;
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
  print FH "file_checksum\t$file_md5\n";
} else {
  foreach my $line (@stats) {
    print FH $line."\n";		
  }
}
close FH;
