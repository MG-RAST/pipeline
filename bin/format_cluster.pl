#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use Getopt::Long;
umask 000;

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

my $clust = [];
my $parse = "";
my $s_num = 0;
my $c_num = 0;
my $c_seq = 0;

open(IN, "<".$input) || exit 1;
open(OUT, ">".$output) || exit 1;

while (my $line = <IN>) {
    chomp $line;
    # process previous cluster
    if ($line =~ /^>Cluster/) {
        ($parse, $s_num) = parse_clust($clust);
        if ($parse) {
            print OUT $parse;
            $c_num += 1;
            $c_seq += $s_num;
        }
        $clust = [];
    } else {
        push @$clust, $line;
    }
}
# process last cluster
($parse, $s_num) = parse_clust($clust);
if ($parse) {
    print OUT $parse;
    $c_num += 1;
    $c_seq += $s_num;
}
close(IN);
close(OUT);

exit 0;

sub get_usage {
    return "USAGE: format_cluster.pl -input=<cd-hit .clstr file> -output=<cluster mapping file> \n";
}

# process cluster file lines
sub parse_clust {
    my ($clust) = @_;
    if (@$clust < 2) {
        # cluster of 1
        return ("", 0);
    }
    my $seed = "";
    my $ids  = [];
    my $pers = [];
    foreach my $x (@$clust) {
        if ($x =~ /\s>(\S+)\.\.\.\s+(\S.*)$/) {
            if ($2 eq '*') {
                $seed = $1;
            } else {
                push @$ids, $1;
                push @$pers, (split(/\s+/, $2))[1];
            }
        } else {
            # bad cluster line
            return ("", 0);
        }
    }
    unless ($seed && (@$ids > 0)) {
        # bad cluster block
        return ("", 0);
    } else {
        return ($seed."\t".join(",", @$ids)."\t".join(",", @$pers)."\n", scalar(@$ids)+1);
    }
}
