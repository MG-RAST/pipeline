#!/usr/bin/env perl 

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

my $usage = qq(
Purpose: adds up prefix entropy and classifies data as random, untrimmed barcode or amplicon 
Usage:   nmerprefix.pl -fasta <FASTA> [-k <max k>] [-m <max seqs>] [-amplicon] [-hint]  [-table]

                -fasta    input fasta file (required)
 		-k        maximum kmer length to index (default 50)  
	  	-m        maximum number of sequences to count (default is 100000)
 		-amplicon output terse judgement of guessed barcode length 
		-hint     prepend filename to output
		-table    human-readable table of prefix entropies 
	                  (default is one long line)
);

my $filename   = "";
my $kmerlength = 50;
my $verbose = "";
my $table = 0;
my $hint = 0;
my $amplicon = 0;
my $max_seqs = 100000;

if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { print STDERR $usage; exit(0); }
if ( ! GetOptions ("fasta=s"      => \$filename,
                   "k:i"          => \$kmerlength,
                   "verbose!"     => \$verbose,
                   "t|table!"     => \$table,
                   "m|max_seqs:i" => \$max_seqs,
                   "amplicon!"    => \$amplicon,
                   "hint!"        => \$hint,
                  )
   ) { print STDERR $usage; exit(0); }

if (! ($filename && (-s $filename))) { die "nmerprefix.pl: input file does not exist!\n$usage"; }
if ($amplicon) { $verbose = 0; }
print STDERR "Kmerlength:$kmerlength\n" if $verbose;
print STDERR "Reading genome data...\n" if $verbose;

my %hash = ();  	# define an empty hash to contain longest-length prefixes
my $log2 = log(2); 	# necessary for units of bits
my $totalcount;
my $n =0;
my @ent="";
my @maxent="";
read_prefixes($filename, $kmerlength);  # populates %hash
# Done with input (staging into %hash)  now time to calculate

print STDERR "\nDone.   Saw $n sequences. Counting...\n" if $verbose;
$totalcount = countthemall(); # count the number of valid sequences
print STDERR "Total valid prefixes: $totalcount\n" if $verbose;

for (my $j = 1; $j <= $kmerlength; $j++) {
  $ent[$j] = addupk($j);   # get the prefix entropy for $j
  print STDERR "caluclating entropy at K=$j\n" if $verbose;
  my $t = (1.0-(1.0-1/4**($j))**$totalcount);  # this is the maximum possible entropy
  if($t > 1E-8) {
    $maxent[$j] = (2.0 * $j ) + log($t) / log(2);
  }
  else {
    $maxent[$j] = log($totalcount) /$log2;
  }
}

if (! $amplicon) {
  if (! $table) { print "$filename\t$totalcount\t"; }  # prepend to output line
  for (my $j = 1; $j <= $kmerlength; $j++) {
    if (! $table) { print "$ent[$j]\t"; } 
    else          { print "$j\t$ent[$j]\t$maxent[$j]\n"; }
  }
  print "\n" if (! $table);
}
else {
  my $description = classify_entropy(\@ent, $totalcount);
  if ($hint) { print "$filename\t$totalcount\t"; }
  print $description."\n";
}

# add up all keys; this needs to be done once
sub countthemall {
  my $totalct = 0;
  foreach my $key (sort keys %hash) {
    $totalct += $hash{$key};
  }
  print STDERR "Total sequences counted: $totalcount\t" if $verbose;
  return $totalct;
}

sub addone {
  my ($element) = @_;
  if (($element =~ /[RYMKSWHBVDNX]/g) == 0) {
    if (defined($hash{$element})) {
      $hash{$element} ++;
    } else {
      $hash{$element} = 1;
    }
  }
}

# loops through already-defined hash of prefixes (hash)
# makes table (shorthash) of short-prefixes
# returns entropy of short-prefix table 
sub addupk {
  my %shorthash = ();
  my $k = shift;
  my $ntot = 0; my $s = 0;
  our $hash;
  foreach my $word (keys %hash) {
    $shorthash{substr($word, 0, $k)} += $hash{$word}; 
    $ntot += $hash{$word};
  }
  foreach my $shortword (keys %shorthash) {
    $s += - ($shorthash{$shortword} / $ntot) * log($shorthash{$shortword} / $ntot) / $log2;
  }
  return($s);
}

sub read_prefixes {
  my $fn = shift;
  my $kk = shift;
  print STDERR "Opening file ...\n" if $verbose;
  local($/, *FILE);
  $/ = "\n>";
  open FILE, "<$fn";
  print STDERR "Done opening  file ...\n" if $verbose;
  my $start = 1;
  my ($label, $rest, $input, $inputline, $sequence, $element, $plength);

  while (<FILE>)  {
    if (length($_)>2 ) {
      last if $n > $max_seqs; 
      $n++;
      $input = $_;
      $inputline=substr($input, 0, 2000); 
      # truncate input lines to 2000 chars; only looking at prefixes
      # (this is for whole genomes)
      if ($inputline =~ /(.*?)\n(.*)/s) {
	$label = $1;
	$rest = $2;
	chomp $label;
	chomp $rest;
	$rest =~ s/\n//g;
      }
      $plength = length($rest);
      $sequence = uc($rest);
      my $i=0;
      {
	$element = substr($sequence, $i, $kk);
	addone($element);
	if($n % 10000 == 10) {
	  print STDERR "nmerprefix.pl: $fn Fragment $n Loaded $plength nucleotides...\n" if $verbose;
	}
      }
    }  # end if 
  }  # end input while
}  # end local 

sub classify_entropy {
  my $b = shift;
  my $tc = shift;
  my @a = @$b;
  # amplicon = -2 / WGS = everything else
  my %labels = (-3 => "Small",  -2 => "Sub-random", -1 =>"Random", 0=>"Unclassified",
		2=>"Barcode 2", 3=>"Barcode 3", 4=>"Barcode 4", 5=>"Barcode 5", 6=>"Barcode 6",
		7=>"Barcode 7", 8=>"Barcode 8", 9=>"Barcode 9", 10=>"Barcode 10", 11=>"Barcode 11",
		12=>"Barcode 12", 13=>"Barcode 13", 14=>"Barcode 14", 15=>"Barcode 15", 16=>"Barcode 16",
		17=>"Barcode 17", 18=>"Barcode 18", 19=>"Barcode 19", 20=>"Barcode 20", 21=>"Barcode 21",
		22=>"Barcode 22", 23=>"Barcode 23", 24=>"Barcode 24", 25=>"Barcode 25", 26=>"Barcode 26",
		27=>"Barcode 27", 28=>"Barcode 28", 29=>"Barcode 29", 30=>"Barcode 30");
  my @da   = diff(@a);
  my @dda  = diff(@da);
  my $call = 0;

  if ($a[15] < 9.8 && $a[10] <6) {$call = -2;} # Check for amplicon
  if ($a[ 6] > 10.5)             {$call = -1;} # check for random
  if ($a[ 3] > 5.25)             {$call = -1;} # check for random

  # Check for barcode-to-random discontinuity 
  for (my $k =2; $k < 30; $k++) {
    if($dda[$k-1] > 1.25 && $da[$k+1] > 1.25) {$call = $k;}
  }
  if($tc < 100) {$call =-3;}  # not going to even guess on tiny datasets
  print STDERR $labels{$call} ."\n" if $verbose;
  return ($labels{$call});
}

# calculates first differences of an array of numbers
sub diff {
  my @aa = @_;
  my @d  = ("");
  for (my $j = 0; $j < $#aa; $j++) {
    $d[$j] = $aa[$j+1] - $aa[$j];
  }
  $d[$#aa] = "";
  return @d;
}
