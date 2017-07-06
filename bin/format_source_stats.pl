#!/usr/bin/env perl

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
my $input   = "";
my $output  = "";
my $help    = 0;
my $options = GetOptions (
        "input=s"  => \$input,
        "output=s" => \$output,
		"help!"    => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (! -s $input){
    print STDERR "input file is missing";
    exit 1;
}elsif (length($output)==0){
    print STDERR "output was not specified";
    exit 1;
}

my $data = {};

open(INPUT, "<$input") or die "Couldn't open input: $!";
while (my $line = <INPUT>) {
    chomp $line;
    my @parts  = split(/\t/, $line);
    my $source = shift @parts;
    if (@parts == 10) {
        $data->{$source}->{evalue}  = [ @parts[0..4] ];
        $data->{$source}->{identity} = [ @parts[5..9] ];
    }
}
close(INPUT);

open(OUTPUT, ">$output") or die "Couldn't open output: $!";
print OUTPUT $json->encode($data);
close(OUTPUT);

exit 0;

sub get_usage {
    return "USAGE: format_source_stats.pl -input=<source abundance profile> -output=<source stats file> \n";
}
