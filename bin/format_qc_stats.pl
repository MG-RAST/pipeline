#!/usr/bin/env perl

#input: file list kmer_stats
#       tabbed drisee stat    (optional)
#       text drisee info      (optional)
#       tabbed consensus stat (optional)
#       tabbed coverage stat  (optional)
#outputs: json ${out_prefix}.qc.summary
#         json ${out_prefix}.qc.stats	

use strict;
use warnings;
no warnings('once');

use JSON;
use List::Util qw(first max min sum);
use POSIX qw(strftime floor);
use Getopt::Long;
umask 000;

my $json = JSON->new;
$json = $json->utf8();
$json->max_size(0);
$json->allow_nonref;

# options
my $drisee_stat = "";
my $drisee_info = "";
my $kmer_lens   = "";
my $kmer_stats  = "";
my $consensus   = "";
my $coverage    = "";
my $out_prefix  = "";
my $help = 0;
my $options = GetOptions (
		"drisee_stat=s" => \$drisee_stat,
		"drisee_info=s" => \$drisee_info,
		"kmer_lens=s"   => \$kmer_lens,
		"kmer_stats=s"  => \$kmer_stats,
		"consensus=s"   => \$consensus,
		"coverage=s"    => \$coverage,
		"out_prefix=s"  => \$out_prefix,
		"help!"         => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($out_prefix)==0){
    print STDERR "out_prefix was not specified";
    exit 1;
}

# kmer input validation
my @klens = split(/,/, $kmer_lens);
my @kfiles = split(/,/, $kmer_stats);
if (@klens == 0) {
    print STDERR "missing kmer_lens option";
    exit 1;
}
if (@kfiles == 0) {
    print STDERR "missing kmer_stats option";
    exit 1;
}
foreach (@klens) {
    if ($_ !~ /^\d+$/) {
        print STDERR "invalid kmer_lens value: $_";
        exit 1;
    }
}
foreach (@kfiles) {
    unless (-s $_) {
        print STDERR "missing kmer_stats file: $_";
        exit 1;
    }
}
if (scalar(@klens) != scalar(@kfiles)) {
    print STDERR "mismatch between kmer_lens and kmer_stats";
    exit 1;
}

# summary stats
my $qcsum = {};

# process drisee
if ((-s $drisee_stat) && (-s $drisee_info)) {
    my $drisee_summary_stats = {
        drisee_input_seqs => 1,
        drisee_processed_bins => 1,
        drisee_processed_seqs => 1,
        drisee_score => 1
    };
    my @bin_stats = `tail -4 $drisee_info`;
    chomp @bin_stats;
    foreach my $line (@bin_stats) {
        my ($key, $val) = split('\t', $line);
        $key =~ s/\s+/_/g;
        $key = lc($key);
        unless ($key =~ /^drisee/i) {
            $key = 'drisee_'.$key
        }
        if (exists $drisee_summary_stats->{$key}) {
            $qcsum->{$key} = $val;
        }
    }
    my $d_score = `head -2 $drisee_stat | tail -1 | cut -f8`;
    chomp $d_score;
    $qcsum->{"drisee_score_raw"} = sprintf("%.3f", $d_score);
}

# process coverage
if (-s $coverage) {
    my $cov_num = 0;
    my $total   = 0;
    open(COV, $coverage) || exit 1;
    while (my $line = <COV>) {
        chomp $line;
        my ($h, $c) = split(/\t/, $line);
        if (int($c) > 1) {
            $cov_num += 1;
        }
        $total += 1;
    }
    close(COV);
    my $percent = sprintf( "%.2f", ( int ( ( ($cov_num / $total) * 10000 ) + 0.5 ) ) / 100 );
    $qcsum->{'percent_reads_with_coverage'} = $percent;
}

# process stats into JSON struct
my $qcstat = {
    drisee     => get_drisee($drisee_stat, $qcsum),
    bp_profile => get_nucleo($consensus),
    kmer       => {}
};
for (my $i=0; $i<scalar(@klens); $i++) {
    $qcstat->{"kmer"}->{$klens[$i]."_mer"} = get_kmer($kfiles[$i], $klens[$i]);
}

# output stats
print_json($out_prefix.".qc.stats", $qcstat);
print_json($out_prefix.".qc.summary", $qcsum);

exit 0;

sub get_usage {
    return "USAGE: format_qc_stats.pl -drisee_stat=<drisee stat file> -drisee_info=<drisee info file> -kmer_lens=<kmer len list> -kmer_stats=<kmer file list> -consensus=<consensus stat file> -coverage=<coverage stat file> -out_prefix=<output prefix>\noutputs: \${out_prefix}.qc.summary, \${out_prefix}.qc.stats\n";
}

sub get_drisee {
    my ($dfile, $stats) = @_;
    
    my $bp_set = ['A', 'T', 'C', 'G', 'N', 'InDel'];
    my $drisee = file_to_array($dfile);
    my $ccols  = ['Position'];
    map { push @$ccols, $_.' match consensus sequence' } @$bp_set;
    map { push @$ccols, $_.' not match consensus sequence' } @$bp_set;
    my $data = { summary  => { columns => [@$bp_set, 'Total'], data => undef },
                 counts   => { columns => $ccols, data => undef },
                 percents => { columns => ['Position', @$bp_set, 'Total'], data => undef }
               };
    unless ($drisee && (@$drisee > 2) && ($drisee->[1][0] eq '#')) {
        return $data;
    }
    for (my $i=0; $i<6; $i++) {
        $data->{summary}{data}[$i] = $drisee->[1][$i+1] * 1.0;
    }
    $data->{summary}{data}[6] = $stats->{drisee_score_raw} ? $stats->{drisee_score_raw} * 1.0 : undef;
    my $raw = [];
    my $per = [];
    foreach my $row (@$drisee) {
        next if ($row->[0] =~ /\#/);
	    @$row = map { int($_) } @$row;
	    push @$raw, $row;
	    if ($row->[0] > 50) {
	        my $x = shift @$row;
	        my $sum = sum @$row;
	        if ($sum == 0) {
	            push @$per, [ $x, 0, 0, 0, 0, 0, 0, 0 ];
	        } else {
	            my @tmp = map { sprintf("%.2f", 100 * (($_ * 1.0) / $sum)) * 1.0 } @$row;
	            push @$per, [ $x, @tmp[6..11], sprintf("%.2f", sum(@tmp[6..11])) * 1.0 ];
            }
	    }
    }
    $data->{counts}{data} = $raw;
    $data->{percents}{data} = $per;
    return $data;
}

sub get_nucleo {
    my ($nfile) = @_;
    
    my $cols = ['Position', 'A', 'T', 'C', 'G', 'N', 'Total'];
    my $nuc  = file_to_array($nfile);
    my $data = { counts   => { columns => $cols, data => undef },
                 percents => { columns => [@$cols[0..5]], data => undef }
               };
    unless ($nuc && (@$nuc > 2)) {
        return $data;
    }
    my $raw = [];
    my $per = [];
    foreach my $row (@$nuc) {
        next if (($row->[0] eq '#') || (! $row->[6]));
        @$row = map { int($_) } @$row;
        push @$raw, [ $row->[0] + 1, $row->[1], $row->[4], $row->[2], $row->[3], $row->[5], $row->[6] ];
        unless (($row->[0] > 100) && ($row->[6] < 1000)) {
    	    my $sum = $row->[6];
    	    if ($sum == 0) {
	            push @$per, [ $row->[0] + 1, 0, 0, 0, 0, 0 ];
	        } else {
    	        my @tmp = map { floor(100 * 100 * (($_ * 1.0) / $sum)) / 100 } @$row;
    	        push @$per, [ $row->[0] + 1, $tmp[1], $tmp[4], $tmp[2], $tmp[3], $tmp[5] ];
	        }
        }
    }
    $data->{counts}{data} = $raw;
    $data->{percents}{data} = $per;
    return $data;
}

sub get_kmer {
    my ($kfile, $num) = @_;
    
    my $cols = [ 'count of identical kmers of size N',
    			 'number of times count occures',
    	         'product of column 1 and 2',
    	         'reverse sum of column 2',
    	         'reverse sum of column 3',
    		     'ratio of column 5 to total sum column 3 (not reverse)'
               ];
    my $kmer = file_to_array($kfile);
    my $data = { columns => $cols, data => undef };
    unless ($kmer && (@$kmer > 1)) {
        return $data;
    }
    foreach my $row (@$kmer) {
        @$row = map { $_ * 1.0 } @$row;
    }
    $data->{data} = $kmer;
    return $data;
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
