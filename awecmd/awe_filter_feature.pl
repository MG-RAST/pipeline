#!/usr/bin/env perl

#input: sequence file, similarity file
#outputs:  sequence file

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use Cwd;
umask 000;

# options
my $in_clust = "";
my $in_sim  = "";
my $in_seq  = "";
my $output  = "";
my $memory  = 8;
my $overlap = 10;
my $help    = 0;
my $options = GetOptions (
    "in_clust=s" => \$in_clust,
    "in_sim=s"   => \$in_sim,
    "in_seq=s"   => \$in_seq,
    "output=s"   => \$output,
    "memory=i"   => \$memory,
    "overlap=i"  => \$overlap,
    "help!"      => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($in_clust)==0){
    print STDERR "ERROR: An input cluster map file was not specified.\n";
    print STDERR get_usage();
    exit 1;
}elsif (length($in_sim)==0){
    print STDERR "ERROR: An input similarity file was not specified.\n";
    print STDERR get_usage();
    exit 1;
}elsif (length($in_seq)==0){
    print STDERR "ERROR: An input sequence file was not specified.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! -e $in_clust){
    print STDERR "ERROR: The input cluster map file [$in_clust] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! -e $in_sim){
    print STDERR "ERROR: The input similarity file [$in_sim] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! -e $in_seq){
    print STDERR "ERROR: The input sequence file [$in_seq] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}elsif (length($output)==0){
    print STDERR "ERROR: An output sequence file was not specified.\n";
    print STDERR get_usage();
    exit 1;
}

if ($overlap < 0) {
    $overlap = 0;
}

my $mem = $memory * 1024;
my $run_dir = getcwd;
my $common  = "common.ids.".time();
my $members = "member.ids.".time();

# get sorted unique sim ids
PipelineAWE::run_cmd("cut -f1 $in_sim | sort -u -T $run_dir -S ${mem}M > $in_sim.sort.ids", 1);
PipelineAWE::run_cmd("rm $in_sim");
# sort clusters by seed, get seed list
PipelineAWE::run_cmd("sort -T $run_dir -S ${mem}M -t \t -k 1,1 -o $in_clust.sort $in_clust");
PipelineAWE::run_cmd("rm $in_clust");
PipelineAWE::run_cmd("cut -f1 $in_clust.sort | uniq -u > $in_clust.sort.seed", 1);
# get subset of sim ids that are cluster seeds
PipelineAWE::run_cmd("comm -12 $in_sim.sort.ids $in_clust.sort.seed > $common", 1);
# get cluster members for each common id
get_cluster_members($common, "$in_clust.sort", $members);
PipelineAWE::run_cmd("rm $common $in_clust.sort $in_clust.sort.seed");
# cat hits and their members / sort
PipelineAWE::run_cmd("cat $in_sim.sort.ids $members | sort -T $run_dir -S ${mem}M > $members.all", 1);
PipelineAWE::run_cmd("rm $in_sim.sort.ids $members");
# tabbed fasta file
PipelineAWE::run_cmd("seqUtil -t $run_dir -i $in_seq -o $in_seq.tab --fasta2tab");
# cat rna ids with fasta ids / sort
PipelineAWE::run_cmd("cat $members.all $in_seq.tab > $in_seq.tab.all", 1);
PipelineAWE::run_cmd("rm $members.all $in_seq.tab");
PipelineAWE::run_cmd("sort -T $run_dir -S ${mem}M -t \t -k 1,1 -o $in_seq.tab.all.sort $in_seq.tab.all");
PipelineAWE::run_cmd("rm $in_seq.tab.all");
# filter
filter_fasta("$in_seq.tab.all.sort", $output, $overlap);

# stats and attributes
my $filter_stats = PipelineAWE::get_seq_stats($output, 'fasta', 1);
PipelineAWE::create_attr($output.'.json', $filter_stats);

# create subset record list
# note: parent and child files NOT in same order
if (-s $output) {
    PipelineAWE::run_cmd("index_subset_seq.py -p $in_seq -c $output -m $memory -t $run_dir");
    PipelineAWE::run_cmd("mv $output.index $output");
}

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
    return "USAGE: awe_filter_feature.pl -in_clust=<input cluster map> -in_sim=<input similarity> -in_seq=<input sequence> -output=<output sequence> [-overlap=<overlap, default: 10> [-memory=<memory usage in GB, default is 16>]\n";
}
