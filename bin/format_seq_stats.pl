#!/usr/bin/env perl

#input: tabbed seq stats
#       tabbed len bin
#       tabbed gc bin
#outputs: json ${out_prefix}.seq.bins
#         json ${out_prefix}.seq.stats	

use strict;
use warnings;
no warnings('once');

use JSON;
use Getopt::Long;
umask 000;

my $json = JSON->new;
$json = $json->utf8();
$json->max_size(0);
$json->allow_nonref;

# options
my $seq_stat   = "";
my $seq_lens   = "";
my $seq_gcs    = "";
my $out_prefix = "";
my $help = 0;
my $options = GetOptions (
        "seq_stat=s"   => \$seq_stat,
        "seq_lens=s"   => \$seq_lens,
        "seq_gcs=s"    => \$seq_gcs,
        "out_prefix=s" => \$out_prefix,
		"help!"        => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (! -s $seq_stat){
    print STDERR "seq_stat file is missing";
    exit 1;
}elsif (! -s $seq_lens){
    print STDERR "seq_lens file is missing";
    exit 1;
}elsif (! -s $seq_gcs){
    print STDERR "seq_gcs file is missing";
    exit 1;
}elsif (length($out_prefix)==0){
    print STDERR "out_prefix was not specified";
    exit 1;
}

# get seq_stats object
my $sstat = {};
open(SSTAT, $seq_stat) || exit 1;
while (my $line = <SSTAT>) {
    chomp $line;
    if ($line =~ /^\[error\]/) {
        logger('error', $line);
        exit 1;
    }
    my ($k, $v) = split(/\t/, $line);
    $sstat->{$k} = $v;
}
close(SSTAT);

# get bins object
my $sbin = {
    length_histogram => file_to_array("$seq_lens"),
    gc_histogram     => file_to_array("$seq_gcs")
};

# output stats
print_json($out_prefix.".seq.stats", $sstat);
print_json($out_prefix.".seq.bins", $sbin);

exit 0;

sub get_usage {
    return "USAGE: format_seq_stats.pl -seq_stat=<stats tabbed file> -seq_lens=<len bin file> -seq_gcs=<gc bin file> -out_prefix=<output prefix>\noutputs: \${out_prefix}.seq.bins, \${out_prefix}.seq.stats\n";
}

sub file_to_array {
    my ($file) = @_;
    my $data = [];
    unless ($file && (-s $file)) {
        return $data;
    }
    open(FILE, "<$file") || return $data;
    while (my $line = <FILE>) {
        chomp $line;
        my @parts = split(/\t/, $line);
        push @$data, [ @parts ];
    }
    close(FILE);
    return $data;
}

sub print_json {
    my ($file, $data) = @_;
    open(OUT, ">$file") or die "Couldn't open file: $!";
    print OUT $json->encode($data);
    close(OUT);
}
