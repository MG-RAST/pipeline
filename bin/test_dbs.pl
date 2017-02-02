#!/usr/bin/env perl

use strict;
use warnings;

use Text::CSV;
use JSON;
use Getopt::Long;
use Data::Dumper;

my $type  = "";
my $file  = "";
my $input = "";
my $build = 0;
my $usage = qq($0
  --type   one of: leveldb, berkeleydb, lmdb
  --file   path to db file
  --input  file with list of test md5s or input data
  --build  build db file
);

if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { print STDERR $usage; exit 1; }
if ( ! GetOptions(
	'type:s'  => \$type,
	'file:s'  => \$file,
	'input:s' => \$input,
	'build!'  => \$build
   ) ) {
    print STDERR $usage; exit 1;
}

unless ($file && (-s $file) && $input && (-s $input)) {
    print STDERR $usage; exit 1;
}

my $csv  = Text::CSV->new;
my $json = JSON->new;
$json = $json->utf8();
$json->max_size(0);
$json->allow_nonref;

# create db hash
my %dbh;
if ($type eq 'leveldb') {
    use Tie::LevelDB;
    tie %dbh, 'Tie::LevelDB', $file;
} elsif ($type eq 'berkeleydb') {
    use BerkeleyDB;
    tie %dbh, "BerkeleyDB::Hash", -Filename => $file, -Flags => DB_RDONLY;
} elsif ($type eq 'lmdb') {
    use LMDB_File;
    tie %dbh, 'LMDB_File', $file;
} else {
    print STDERR $usage; exit 1;
}
unless (%dbh) {
    print STDERR "Unable to open $file with %type library\n"; exit 1;
}

my $count = 0;
my $start = time;
open(INPUT, "<$input");
if ($build) {
    ### must be ordered by md5
    ### each md5-source combo is unique
    my $prev = "";
    my $md5  = "";
    my @data = ();
    while (my $row = $csv->getline(INPUT)) {
        $count += 1;
        $md5 = $row->[0];
        unless ($prev) {
            $prev = $md5; # for first line only
        }
        if ($prev ne $md5) {
            $dbh{$prev} = $json->encode(\@data);
            $prev = $md5;
            @data = ();
        }
        my $ann = {
            source     => $row->[1],
            is_protein => ($row->[2] eq 'true') ? 1 : 0,
            single     => $row->[3],
            lca        => $json->decode($row->[4]),
            accession  => $json->decode($row->[5]),
            function   => $json->decode($row->[6]),
            organism   => $json->decode($row->[7])
        };
        push @data, $ann;
    }
    if (scalar(@data) > 0) {
        $dbh{$md5} = $json->encode(\@data);
    }
} else {
    my $srcs = {}
    while (my $md5 = <INPUT>) {
        $count += 1;
        chomp $md5;
        my $ann = $json->decode( $dbh{$md5} );
        if (exists $src->{$ann->{source}}) {
            $src->{$ann->{source}} += 1;
        } else {
            $src->{$ann->{source}} = 1;
        }
    }
    print Dumper($srcs);
}
close(INPUT);
my $end = time;

print "Processed $count lines in ".($end-$start)."seconds\n";
