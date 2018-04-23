#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use Cwd;
umask 000;

# options
my $fasta  = "";
my $output = "";
my $rna_nr = "md5rna.clust.fasta";
my $index  = "m5rna.clust.index";
my $proc   = 8;
my $mem    = 4096;
my $eval   = 0.1;
my $ident  = 75;
my $help   = 0;
my $options = GetOptions (
		"input=s"  => \$fasta,
        "output=s" => \$output,
		"rna_nr=s" => \$rna_nr,
		"index=s"  => \$index,
		"proc:i"   => \$proc,
		"mem:i"    => \$mem,
		"eval:f"   => \$eval,
		"ident:i"  => \$ident,
		"help!"    => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($fasta)==0){
    PipelineAWE::logger('error', "input file was not specified");
    exit 1;
}elsif (length($output)==0){
    PipelineAWE::logger('error', "output file was not specified");
    exit 1;
}elsif (! -e $fasta){
    PipelineAWE::logger('error', "input sequence file [$fasta] does not exist");
    exit 1;
}

if ($ENV{'REFDBPATH'}) {
  $rna_nr = $ENV{'REFDBPATH'}."/".$rna_nr;
  $index  = $ENV{'REFDBPATH'}."/".$index;
}
unless (-s $rna_nr) {
    PipelineAWE::logger('error', "rna_nr does not exist: $rna_nr");
    exit 1;
}

my $run_dir = getcwd;

# use sortmerna
PipelineAWE::run_cmd("sortmerna -a $proc -m $mem -e $eval --blast '1 cigar qcov qstrand' --ref '$rna_nr,$index' --reads $fasta --aligned $fasta", 1);
PipelineAWE::run_cmd("seqUtil -t $run_dir -i $fasta -o $fasta.sort.tab --sortbyid2tab");
PipelineAWE::run_cmd("sort -T $run_dir -t \t -k 1,1 -o $fasta.sort.blast $fasta.blast");

# uc -> fasta
open(OUT, ">$output") || die "Can't open file $output!\n";
open(STAB, "<$fasta.sort.tab") || die "Can't open file $fasta.sort.tab!\n";
open(SBLAST, "<$fasta.sort.blast") || die "Can't open file $fasta.sort.blast!\n";

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
    if (length($seq) > $cstart) {
        my $seq_match = substr($seq, $cstart, $clen);
        if (length($seq_match) > 0) {
            if (length($seq_match) < $clen) {
                $cstop = $cstop - ($clen - length($seq_match));
            }
            print OUT ">${qname}_${cstart}_${cstop}_${strand}\n$seq_match\n";
        }
    }
}

close(SBLAST);
close(STAB);
close(OUT);

exit 0;

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


sub get_usage {
    return "USAGE: mgrast_sortme_rna.pl -input=<input fasta> -output=<output fasta> [-rna_nr=<rna cluster sequences, default: md5rna.clust.fasta> -index=<rna cluster index, default: md5rna.clust.index> -proc=<number of threads, default: 8> -mem=<memory in mb, default: 4096> -eval=<e-value, default: 0.1> -ident=<ident percentage, default: 75>] \n";
}
