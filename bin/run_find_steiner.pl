#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

my ($fasta_file, $bin_name, $out_file, $log_file, $tmp_dir);
my $max_iter = 10;
my $min_conv = 3;

if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage; }
if ( ! GetOptions( "in_file=s"   => \$fasta_file,
		   "out_file=s"  => \$out_file,
		   "tmp_dir=s"   => \$tmp_dir,
		   "log_file:s"  => \$log_file,
		   "max_iter:i"  => \$max_iter,
		   "min_conv:i"  => \$min_conv
		 )
   ) { &usage; }

unless ($fasta_file && $out_file && $tmp_dir && (-d $tmp_dir)) { &usage; }

my $log_text   = "";
my $seed_seq   = "";
my $curr_val   = 0;
my $tmp_id     = unpack("H*", pack("Nn", time, $$));
my $fasta_hash = &get_fasta_hash($fasta_file);

my ($fa_file, $uc_file, $seed_head, $score, @prev_val);

for (my $j = 0; $j < ($min_conv - 1); $j++) {
  $prev_val[$j] = 0;
}

my $i;

ML: for ($i = 1; $i <= $max_iter; $i++) {
  # propagate converge values
  for (my $v = (@prev_val - 1); $v > 0; $v--) {
    $prev_val[$v] = $prev_val[$v-1];
  }
  $prev_val[0] = $curr_val;
  
  $fa_file   = "$tmp_dir/$tmp_id.$i.fasta";
  $uc_file   = "$tmp_dir/$tmp_id.$i.results";
  $seed_head = "$tmp_id.$i";

  # create fasta file with seed seq
  if ($seed_seq) {
    system("echo '>$seed_head\n$seed_seq\n' | cat - $fasta_file > $fa_file");
  } else {
    system("cp $fasta_file $fa_file");
  }

  # get qiime-uclust score and seed seq
  system("qiime-uclust --sort $fa_file --output $fa_file.sort --tmpdir $tmp_dir > /dev/null 2>&1");
  $log_text .= `qiime-uclust --input $fa_file.sort --uc $uc_file --id 0 --tmpdir $tmp_dir --rev 2>&1`;
  ($score, $seed_seq) = &get_steiner($fasta_hash, $seed_head, $seed_seq, $uc_file);

  # test if converged
  $curr_val = &get_converge($log_text);
  foreach (@prev_val) { if ($curr_val ne $_) { next ML; } }
  last;
}

# done - print outputs / cleanup
$log_text =~ s/\r/\n/g;
&write_file($log_file, "$log_text\n$uc_file\n") if ($log_file);
&write_file($out_file, $score);

system("rm $tmp_dir/$tmp_id.*");

sub get_steiner {
  my ($fasta, $s_head, $s_seq, $uc) = @_;

  my (%id2pat, @stats);
  my @ucs = &read_file($uc);

  # parse UC file
  foreach my $line ( @ucs ) {
    if ( $line =~ /^#/ ) { next; }
    my @r = split(/\s+/, $line);
    if ( $r[0] ne "H" ) { next; }

    $r[7] =~ s/([MID])/$1 /g;
    $id2pat{ $r[8] } = [ split(/ /, $r[7]) ];
  }

  # parse fasta hash
  if ($s_seq) { $fasta->{$s_head} = $s_seq; }

  while ( my ($id, $seq) = each %$fasta ) {
    unless ( exists $id2pat{$id} ) { next; }
    my $pos    = 0;
    my $tmpseq = "";

    foreach my $v ( @{$id2pat{$id}} ) {
      if ( $v =~ /^(\d*)([MID])/ ) {
	my $num  = ($1 ne "") ? int($1) : 1;
	my $type = $2;
	if ($type eq "M") {
	  $tmpseq .= substr($seq, $pos, $num);
	  $pos += $num;
	} elsif ($type eq "D") {
	  $pos += $num;
	} elsif ($type eq "I") {
	  $tmpseq .= "X" x $num;
	}
      }
    }
    $tmpseq = uc $tmpseq;
    my @tmparray = split(//, $tmpseq);
    for (my $i = 0; $i < @tmparray; $i++) {
      $stats[$i]{ $tmparray[$i] } += 1;
    }
  }
  delete $fasta->{$s_head};

  # create results
  my @bases     = ("A", "T", "C", "G", "N", "X");
  my $new_seed  = "";
  my $new_score = join("\t", @bases) . "\n";

  for (my $i = 0; $i < @stats; $i++) {
    my @row = ();
    my @tmp = ("", 0);
    foreach my $b (@bases) {
      my $sum = 0;
      if ( exists $stats[$i]{$b} ) {
	$sum = $stats[$i]{$b};
	if ( ($b =~ /[AGCTN]/i) && ($tmp[1] < int($stats[$i]{$b})) ) {
	  @tmp = ($b, int($stats[$i]{$b}));
	}
      }
      push @row, $sum;
    }
    $new_seed  .= $tmp[0];
    $new_score .= join("\t", @row) . "\n";
  }

  return ($new_score, $new_seed);
}

sub get_converge {
  my ($log) = @_;

  my $x = 0;
  if ($log =~ /(\S+)%\s+$/) {
    $x = $1;
  }
  return $x;
}

sub get_fasta_hash {
  my ($file) = @_;

  my $text   = &read_file($file);
  my %fastas = ();
  foreach my $entry ( split(/\n>/, $text) ) {
    my @lines = split(/\n/, $entry);
    my $head  = shift @lines;
    if ( $head =~ />?(\S+)/ ) {
      $fastas{ $1 } = join("", @lines);
    }
  }

  return \%fastas;
}

sub read_file {
  my ($file) = @_;

  my $string = "";
  local( *FH );
  if ( sysopen( FH, $file, 0 ) ) {
    unless ( sysread( FH, $string, -s FH ) ) {
      die "Can not read file $file: $!\n";
    }
  } else {
    die "Can not open file $file: $!\n";
  }
  return wantarray() ? split(/\n/, $string) : $string;
}

sub write_file {
  my ($file, $text) = @_;
  
  local( *FH );
  system("touch $file");
  if ( sysopen( FH, $file, 1 ) ) {
    unless ( syswrite( FH, $text ) ) {
      die "Can not write file $file: $!\n";
    }
  } else {
    die "Can not open file $file: $!\n";
  }
}

sub usage {
  print STDERR "Usage: " . (split(/\//, $0))[-1] . qq(

Runs qiime-uclust sort, qiime-uclust search, find Stiener on given fasta file
for given number of iterations (or until converges).

Result to out_file:
line 1:  Base pair header (A T C G N X)
line 2+: count for each bp, each position on one line

    --in_file    (string,       required)  fasta file to process
    --out_file   (string,       required)  file for output (score matrix for bin)
    --tmp_dir    (string,       required)  dir to store intermediate results (cleaned at end)
    --log_file   (string,       optional)  file for log data
    --max_iter   (integer,  default = 10)  maximum number of qiime-uclust iterations if no convergence
    --min_conv   (integer,   default = 3)  minimum number of iterations to identify convergence (and stop qiime-uclust)

);
  exit;
}
