#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use JSON;
use Getopt::Long;

my $json = JSON->new;
$json = $json->utf8();
$json->max_size(0);
$json->allow_nonref;

# read in parameters
my $help    = 0;
my $input   = '';
my $stats   = '';
my $output  = '';
my $removed = '';

my $filter_ln    = 0;
my $filter_ambig = 0;
my $deviation    = 2.0;
my $max_ambig    = 5;

my $options = GetOptions ( 
	     'input=s'       => \$input,
	     'stats=s'       => \$stats,
	     'output=s'      => \$output,
	     'removed=s'     => \$removed,
	     'deviation:f'   => \$deviation,
	     'max_ambig:i'   => \$max_ambig,
	     'filter_ln!'    => \$filter_ln,
 	     'filter_ambig!' => \$filter_ambig,
	     'help!'         => \$help
);

my $usage = "
  usage:  filter_fasta.pl -i input_fasta -s input_stats -o output_fasta -r reject_fasta [-filter_ln -deviation=XX] [-filter_ambig -max_ambig=XX]

  filter fasta file based on sequence length and/or on number of ambiguity characters (Ns)
  skipping both filters is equivalent to copying the file, but slower
  
    -input         input fasta sequence file (required)
    -stats         input sequence stats file, json format (required)
    -output        output fasta file (required)
    -removed       removed fasta file, sequences which are filtered out will get written to the specified file
    
    -filter_ln     flag to request filtering on sequence length
    -filter_ambig  flag to request filtering on ambiguity characters
    -deviation     stddev mutliplier for calculating min / max length for rejection
    -max_ambig     maximum number of ambiguity characters (Ns) in a sequence which will not be rejected

";

if ($help){
    print $usage;
    exit 0;
}elsif (! -s $input){
    print STDERR "input file is missing";
    exit 1;
}elsif (! -s $stats){
    print STDERR "stats file is missing";
    exit 1;
}elsif (length($output)==0){
    print STDERR "output file is missing";
    exit 1;
}

# get min / max cutoffs
my $sstat  = read_json($stats);
my $min_ln = int( $sstat->{average_length} - ($deviation * $sstat->{standard_deviation_length}) );
my $max_ln = int( $sstat->{average_length} + ($deviation * $sstat->{standard_deviation_length}) );
if ($min_ln < 0) {
    $min_ln = 0;
}

filter_fasta($input, $output, $removed, $min_ln, $max_ln, $max_ambig);

exit 0;

sub filter_fasta {
    my($infile, $fasta_out, $fasta_reject, $min_ln, $max_ln, $max_ambig) = @_;
    
    my $old_eol = $/;
    $/ = "\n>";
    
    open(IN,  "<$infile") or die "could not open file '$infile': $!";
    open(OUT, ">$fasta_out") or die "could not open file '$fasta_out': $!";
    if ($fasta_reject) {
	    open(REJECT, ">$fasta_reject") or die "could not open file '$fasta_reject': $!";
    }
    
    my $rec;
    while ( defined($rec = <IN>) ) {
	    $rec =~ s/^>*//;
	    chomp $rec;
	
	    my $id = "";
	    my ($id_line, @seq_lines) = split("\n", $rec);
	    if ($id_line =~ /^(\S+)/) {
	        $id = $1;
	    }
	    unless ($id) { next; }
	
	    my $seq = \join('', @seq_lines);  # scalar reference to the sequence string
	    my $ln_ok    = length_is_ok($filter_ln, $seq, $min_ln, $max_ln);
	    my $ambig_ok = ambig_chars_is_ok($filter_ambig, $seq, $max_ambig);
	
	    if ($ln_ok && $ambig_ok) {
	        print OUT join("\n", ">$id", @seq_lines), "\n";
	    } else {
	        if ($fasta_reject) {
		        print REJECT join("\n", ">$id", @seq_lines), "\n";
	        }
	    }
    }
    
    if ($fasta_reject) {
	    close(REJECT) or die "could not close file '$fasta_reject': $!";
    }
    close(OUT) or die "could not close file '$fasta_out': $!";
    close(IN) or die "could not close file '$infile': $!";
    $/ = $old_eol;
}

sub length_is_ok {
    my($filter_ln, $seq, $min_ln, $max_ln) = @_;
    my $ln_ok = 1;
    if ($filter_ln) {
	    my $seq_ln = length($$seq);
	    if (($seq_ln < $min_ln) || ($seq_ln > $max_ln)) {
	        # length is not OK
	        $ln_ok = 0;
	    }
    }
    return $ln_ok;
}
    
sub ambig_chars_is_ok {
    my($filter_ambig, $seq, $max_ambig) = @_;
    my $ambig_ok = 1;
    if ($filter_ambig) {
        my $n_ambig = ($$seq =~ tr/[nN]/N/);
        if ($n_ambig > $max_ambig) {
            # ambig is not OK
            $ambig_ok = 0;
        }
    }
    return $ambig_ok;
}

sub read_json {
    my ($file) = @_;
    my $data = {};
    if (-s $file) {
        open(IN, "<$file") or die "Couldn't open file: $!";
        $data = $json->decode(join("", <IN>)); 
        close(IN);
    }
    return $data;
}
