#!/usr/bin/env perl

#input: fasta
#outputs:  ${out_prefix}.aa${pid}.faa, ${out_prefix}.aa${pid}.mapping
#            OR
#          ${out_prefix}.rna${pid}.fna, ${out_prefix}.rna${pid}.mapping
#            OR
#          ${out_prefix}.dna${pid}.fna, ${out_prefix}.dna${pid}.mapping

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
umask 000;

# options
my $out_prefix = "cluster";
my $fasta   = "";
my $pid     = 90;
my $memory  = 16;
my $aa      = 0;
my $rna     = 0;
my $dna     = 0;
my $help    = 0;
my $options = GetOptions (
        "out_prefix=s" => \$out_prefix,
        "input=s"  => \$fasta,
		"pid=i"    => \$pid,
		"memory=i" => \$memory,
		"aa!"      => \$aa,
        "rna!"     => \$rna,
        "dna!"     => \$dna,
        "help!"    => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($fasta)==0){
    print STDERR "ERROR: An input file was not specified.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! -e $fasta){
    print STDERR "ERROR: The input sequence file [$fasta] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}elsif ((! $pid) || ($pid < 40)){
    print STDERR "ERROR: The percent identity must be greater than 50\n";
    print STDERR get_usage();
    exit 1;
}elsif ((! $aa) && (! $rna) && (! $dna)){
    print STDERR "ERROR: one of the following modes is required: aa, rna, dna\n";
    print STDERR get_usage();
    exit 1;
}

my ($cmd, $word, $code, $output);
if ($aa) {
    ($cmd, $word, $code, $output) = ("cd-hit", word_length("aa", $pid), "aa", $out_prefix.".aa".$pid.".faa");
} else {
    $code = $rna ? 'rna' : 'dna';
    ($cmd, $word, $output) = ("cd-hit-est", word_length($code, $pid), $out_prefix.".".$code.$pid.".fna");
}
my $mem = $memory * 1024;
# run clustering
PipelineAWE::run_cmd("$cmd -n $word -d 0 -T 0 -M $mem -c 0.$pid -i $fasta -o $output");

# turn $output.clstr into $output.mapping
my $clust = [];
my $parse = "";
my $s_num = 0;
my $c_num = 0;
my $c_seq = 0;
my $mapf  = $out_prefix.".".$code.$pid.".mapping";

open(IN, "<".$output.".clstr") || exit 1;
open(OUT, ">".$mapf) || exit 1;

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
unlink($output.".clstr");

# get stats
#my $fast = $aa ? 1 : 0;
#my $seq_stats = PipelineAWE::get_seq_stats($output, 'fasta', $fast);
#my $cls_stats = {cluster_count => $c_num, clustered_sequence_count => $c_seq};

# output attributes
PipelineAWE::create_attr($output.".json", undef, {data_type => "sequence", file_format => "fasta"});
PipelineAWE::create_attr($mapf.".json", undef, {data_type => "cluster", file_format => "text"});

exit 0;

sub get_usage {
    return "USAGE: awe_cluster.pl -input=<input fasta> <-aa|-rna|-dna> -pid=<percentage of identification, default 90> [-out_prefix=<output prefix> -memory=<memory usage in GB, default is 16>]\n";
}

# process cluster file lines
sub parse_clust {
    my ($clust) = @_;
    
    if (@$clust < 2) {
        return ("", 0); # cluster of 1
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
            print STDERR "Warning: bad cluster line: $x\n";
            return ("", 0);
        }
    }
    unless ($seed && (@$ids > 0)) {
        print STDERR "Warning: bad cluster block\n";
        return ("", 0);
    } else {
        return ($seed."\t".join(",", @$ids)."\t".join(",", @$pers)."\n", scalar(@$ids)+1);
    }
}

# determine optimal word length for clustering
sub word_length {
    my ($type, $pid) = @_;
    
    if ($type eq 'aa') {
        if ($pid > 70) {
            return 5;
        } elsif ($pid > 60) {
            return 4;
        } elsif ($pid > 50) {
            return 3;
        } else {
            return 2;
        }
    } else {
        if ($pid > 98) {
            return 10;
        } elsif ($pid > 95) {
            return 9;
        } elsif ($pid > 90) {
            return 8;
        } elsif ($pid > 88) {
            return 7;
        } elsif ($pid > 85) {
            return 6;
        } elsif ($pid > 80) {
            return 5;
        } elsif ($pid > 75) {
            return 4;
        } elsif ($pid > 60) {
            return 3;
        } else {
            return 2;
        }
    }
}

