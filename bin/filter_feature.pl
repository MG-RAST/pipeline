#!/usr/bin/env perl

#input: sequence file, similarity file, cluster file
#outputs:  sequence file

use strict;
use warnings;
no warnings('once');

use Getopt::Long;
use Cwd;
umask 000;

# options
my $in_clust = "";
my $in_sim  = "";
my $in_seq  = "";
my $output  = "";
my $tmp_dir = "";
my $memory  = 8192;
my $overlap = 10;
my $help    = 0;

my $options = GetOptions (
    "clust=s"   => \$in_clust,
    "sim=s"     => \$in_sim,
    "seq=s"     => \$in_seq,
    "output=s"  => \$output,
	"tmpdir:s"  => \$tmp_dir,
    "memory:i"  => \$memory,
    "overlap:i" => \$overlap,
    "help!"     => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($in_clust)==0){
    print STDERR "input cluster map file was not specified";
    exit 1;
}elsif (length($in_sim)==0){
    print STDERR "input similarity file was not specified";
    exit 1;
}elsif (length($in_seq)==0){
    print STDERR "input sequence file was not specified";
    exit 1;
}elsif (! -e $in_clust){
    print STDERR "input cluster map file [$in_clust] does not exist";
    exit 1;
}elsif (! -e $in_sim){
    print STDERR "input similarity file [$in_sim] does not exist";
    exit 1;
}elsif (! -e $in_seq){
    print STDERR "input sequence file [$in_seq] does not exist";
    exit 1;
}elsif (length($output)==0){
    print STDERR "output sequence file was not specified";
    exit 1;
}

if ($overlap < 0) {
    $overlap = 0;
}

unless ($tmp_dir) {
	$tmp_dir = getcwd;
}

my $common  = "common.ids.".time();
my $members = "member.ids.".time();

# get sorted unique sim ids
system("cut -f1 $in_sim | sort -u -T $tmp_dir -S ${memory}M > $in_sim.sort.ids");
# sort clusters by seed, get seed list
system(split(/ /, "sort -T $tmp_dir -S ${memory}M -t \t -k 1,1 -o $in_clust.sort $in_clust"));
system("cut -f1 $in_clust.sort | uniq -u > $in_clust.sort.seed");
# get subset of sim ids that are cluster seeds
system("comm -12 $in_sim.sort.ids $in_clust.sort.seed > $common");
# get cluster members for each common id
get_cluster_members($common, "$in_clust.sort", $members);
# cat hits and their members / sort
system("cat $in_sim.sort.ids $members | sort -T $tmp_dir -S $${memory}M > $members.all");
# cat rna ids with fasta ids / sort
system("cat $members.all $in_seq > $in_seq.all");
system(split(/ /, "sort -T $tmp_dir -S ${memory}M -t \t -k 1,1 -o $in_seq.all.sort $in_seq.all"));
# filter
filter_fasta("$in_seq.all.sort", $output, $overlap);

exit 0;

sub get_cluster_members {
    my ($hits, $clust, $out) = @_;
    
    open(HIT, "<$hits")  || die "Can't open file $hits!\n";
    open(CLU, "<$clust") || die "Can't open file $clust!\n";
    open(OUT, ">$out")   || die "Can't open file $out!\n";

    my $cline = <CLU>;
    chomp $cline;
    my ($seed, $members, $percents) = split(/\t/, $cline);
    
    while (my $hit = <HIT>) {
        chomp $hit;
        unless ($hit) { next; }
        while ($seed ne $hit) {
            $cline = <CLU>;
            unless (defined($cline)) { last; }
            chomp $cline;
            ($seed, $members, $percents) = split(/\t/, $cline);
        }
        foreach my $id (split(/,/, $members)) {
            print OUT $id."\n";
        }
    }
    close OUT;
    close CLU;
    close SIM;
}

sub filter_fasta {
    my ($input, $output, $overlap) = @_;
    
    open(IN, "<$input") || die "Can't open file $input!\n";
    open(OUT, ">$output") || die "Can't open file $output!\n";
    
    my $prev  = "";
    my @prots = ();
    my @rnas  = ();
    
    while (my $line = <IN>) {
        chomp $line;
        my ($id, $seq) = split(/\t/, $line);
        if ($id =~ /^(.+)_(\d+)_(\d+)_(\+|-)$/) {
            my ($read, $start, $stop, $dir) = ($1, $2, $3, $4);
            # process by read id
            if (@prots && ($prev ne $read)) {
                print OUT process_reads(\@prots, \@rnas, $prev);
                @rnas  = ();
                @prots = ();
            }
            if ($seq) {
                push @prots, [$start, $stop, $dir, $seq];
            } else {
                push @rnas, [$start, $stop];
            }
            $prev = $read;
        }
    }
    close IN;
    
    # handle last batch
    if (@prots) {
        print OUT process_reads(\@prots, \@rnas, $prev);
    }
    close OUT;
}

sub process_reads {
    my ($prots, $rnas, $read) = @_;
    my $out_text = "";
    foreach my $prot (@$prots) {
        my ($pstart, $pstop, $pdir, $pseq) = @$prot;
        my $write_record = 1;
        if (@$rnas) {
            foreach my $rna (@$rnas) {
                my ($rstart, $rstop) = @$rna;
                # do filter
                if ( (($pstart > ($rstart + $overlap)) && ($pstart < ($rstop - $overlap))) ||
                     (($pstop > ($rstart + $overlap)) && ($pstop < ($rstop - $overlap))) ||
                     (($pstart < ($rstart + $overlap)) && ($pstop > ($rstop - $overlap)))
                   ) {
                    # we will skip this prot
                    $write_record = 0;
                    last;
                }
            }
        }
        if ($write_record) {
            # not filtered
            $out_text .= ">${read}_${pstart}_${pstop}_${pdir}\n$pseq\n";
        }
    }
    return $out_text;
}

sub get_usage {
    return "USAGE: filter_feature.pl -clust=<input cluster map> -sim=<input similarity> -seq=<input sorted-tabbed sequence> -output=<output fasta sequence> [-overlap=<bp overlap, default: 10> -memory=<memory usage in MB, default is 8192> -tmpdir=<temp directory>]\n";
}
