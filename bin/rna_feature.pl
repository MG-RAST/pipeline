#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use Getopt::Long;
umask 000;

# options
my $seqfile = "";
my $simfile = "";
my $output  = "";
my $ident   = 75;
my $help    = 0;
my $options = GetOptions (
        "seq=s"    => \$seqfile,
        "sim=s"    => \$simfile,
        "output=s" => \$output,
        "ident:i"  => \$ident,
		"help!"    => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (! -s $seqfile){
    print STDERR "seq file is missing";
    exit 1;
}elsif (! -s $simfile){
    print STDERR "sim file is missing";
    exit 1;
}elsif (length($output)==0){
    print STDERR "output was not specified";
    exit 1;
}

open(OUT, ">$output") || die "Can't open file $output!\n";
open(STAB, "<$seqfile") || die "Can't open file $seqfile!\n";
open(SBLAST, "<$simfile") || die "Can't open file $simfile!\n";

my $seql = <STAB>;
chomp $seql;
my ($id, $seq) = split(/\t/, $seql);
$id =~ s/^\s+|\s+$//g;

while (my $line = <SBLAST>) {
    chomp $line;
    my @parts = split(/\t/, $line);
    if (scalar(@parts) < 15) {
        next;
    }
    my ($qname, $pident, $qstart, $cigar, $strand) = ($parts[0], $parts[2], $parts[6], $parts[12], $parts[14]);
    if ($pident < $ident) {
        next;
    }
    my @qname_fields = split(/ /, $qname);
    $qname = $qname_fields[0];
    $qname =~ s/^\s+|\s+$//g;
    $qstart = ($qstart < 1) ? 0 : $qstart - 1;
    while ($qname ne $id) {
        $seql = <STAB>;
        unless (defined($seql)) { last; }
        chomp $seql;
        ($id, $seq) = split(/\t/, $seql);
        $id =~ s/^\s+|\s+$//g;
    }
    my ($cstart, $cstop, $clen) = parse_cigar($cigar, $qstart);
    my $seq_match = substr($seq, $cstart, $clen);
    if (length($seq_match) < $clen) {
        $cstop = $cstop - ($clen - length($seq_match));
    }
    print OUT ">${qname}_${cstart}_${cstop}_${strand}\n$seq_match\n";
}

close(SBLAST);
close(STAB);
close(OUT);

exit 0;

sub get_usage {
    return "INPUTS:\n1. tabbed file with id in first column and sequence in second column; sorted by id\n2. blast m8 format file with added columns: cigar, qcov, qstrand; sorted by query id\nUSAGE:\nrna_feature.pl -seq=<sort tab seq file> -sim=<sor blast file> -output=<output file> -ident=<ident percentage, default: 75>\n";
}

sub parse_cigar {
    my ($cigar, $qstart) = @_;
    my $qlen  = cigar_length($cigar);
    my $qstop = $qstart + $qlen;
    my @cigs  = ();
    while ($cigar =~ /([0-9]*)([DMI])/g) {
        my $n = $1 ? $1 : 1;
        push @cigs, [$n, $2];
    }
    if ($cigs[0][1] eq 'D') {
        $qstart = $qstart + $cigs[0][0];
    }
    if ($cigs[-1][1] eq 'D') {
        $qstop = $qstop - $cigs[-1][0];
    }
    return ($qstart, $qstop, $qstop - $qstart);
}

sub cigar_length {
    my ($cigar) = @_;
    my $len = 0;
    while ($cigar =~ /([0-9]*)([DMI])/g) {
        if ($2 eq 'I') {
            next;
        }
        if ($1) {
            $len += $1;
        } else {
            $len += 1;
        }
    }
    return $len;
}
