#!/usr/bin/env perl

#input: .fna or .fastq
#outputs: ${out_prefix}.drisee.stats, ${out_prefix}.drisee.info,
#         ${out_prefix}.consensus.stats, ${out_prefix}.kmer.$len.stats,
#         ${out_prefix}.assembly.coverage
#         ${out_prefix}.qc.stats

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use List::Util qw(first max min sum);
use POSIX qw(strftime floor);
use Getopt::Long;
use Cwd;
umask 000;

# options
my $infile = "";
my $format = "";
my $name   = "raw";
my $proc   = 8;
my $kmers  = '15,6';
my $out_prefix = "qc";
my $assembled  = 0;
my $filter_options = "";
my $help = 0;
my $options = GetOptions (
		"input=s"  => \$infile,
		"format=s" => \$format,
		"name=s"   => \$name,
		"proc=i"   => \$proc,
		"kmers=s"  => \$kmers,
		"out_prefix=s" => \$out_prefix,
        "assembled=i"  => \$assembled,
        "filter_options=s" => \$filter_options,
		"help!" => \$help,
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($infile)==0){
    print STDERR "ERROR: An input file was not specified.\n";
    print STDERR get_usage();
    exit 1;
}elsif (! -e $infile){
    print STDERR "ERROR: The input sequence file [$infile] does not exist.\n";
    print STDERR get_usage();
    exit 1;
}elsif ($infile !~ /\.(fna|fasta|fq|fastq)$/i) {
    print STDERR "ERROR: The input sequence file must be fasta or fastq format.\n";
    print STDERR get_usage();
    exit 1;
}

my @kmers = split(/,/, $kmers);
my $bad_kmer = 0;
foreach (@kmers) {
    if ($_ !~ /^\d+$/) { $bad_kmer = 1; }
}
if ((@kmers == 0) || $bad_kmer) {
    print STDERR "ERROR: invalid kmeer list: $kmers.\n";
    exit 1;
}
unless ($format && ($format =~ /^fasta|fastq$/)) {
    $format = ($infile =~ /\.(fq|fastq)$/) ? 'fastq' : 'fasta';
}

my %value_opts = ();
for my $ov (split ":", $filter_options) {
    if ($ov =~ /=/) {
        my ($option, $value) = split "=", $ov;
        $value_opts{$option} = $value;
    }
}

my $qc_out  = $out_prefix.".qc.stats";
my $seq_out = $out_prefix.".upload.stats";
my $d_stats = $out_prefix.".drisee.stats";
my $d_info  = $out_prefix.".drisee.info";
my $c_stats = $out_prefix.".consensus.stats";
my $a_file  = $out_prefix.".assembly.coverage";
my $qc_stat = {};
my $run_dir = getcwd;
my $a_text  = ($assembled == 1) ? "yes" : "no";

# run full sequence stats with bins
my $seq_stats = PipelineAWE::get_seq_stats($infile, $format, undef, $seq_out);
$seq_stats->{file_size} = -s $infile;

if ($assembled != 1) {
    # create drisee table
    PipelineAWE::run_cmd("drisee -v -p $proc -t $format -d $run_dir -f $infile $d_stats > $d_info", 1);
    
    # get summary drisee
    if (-s $d_stats) {
        my $d_score = `head -2 $d_stats | tail -1 | cut -f8`;
        chomp $d_score;
        $qc_stat->{"drisee_score_raw"} = sprintf("%.3f", $d_score);
    }
    
    # create consensus table
    my $max_ln = 600;
    if (exists $value_opts{"max_ln"}) {
        $max_ln = min($max_ln, $value_opts{"max_ln"});
    } elsif (exists $seq_stats->{length_max}) {
        $max_ln = min($max_ln, $seq_stats->{length_max});
    } else {
        $max_ln = 100;
    }
    PipelineAWE::run_cmd("consensus.py -v -b $max_ln -t $format -i $infile -o $c_stats");
    PipelineAWE::run_cmd("touch $a_file");
} else {
    PipelineAWE::run_cmd("touch $d_stats");
    PipelineAWE::run_cmd("touch $d_info");
    PipelineAWE::run_cmd("touch $c_stats");
    # create assembly abundance file
    my $cov_found_count = 0;
    my $total_reads = 0;
    open ABUN, ">$a_file" || exit 1;
    open SEQS, $infile || exit 1;
    while (my $line = <SEQS>) {
        chomp $line;
        if ($line =~ /^>(\S+\_\[cov=(\S+)\]\S*).*$/) {
            my $seq = $1;
            my $abun = $2;
            print ABUN "$seq\t$abun\n";
            $cov_found_count++;
            $total_reads++;
        } elsif ($line =~ /^>(\S+).*$/) {
            my $seq = $1;
            print ABUN "$seq\t1\n";
            $total_reads++;
        }
    }
    close SEQS;
    close ABUN;
    # create assembly abundace stats
    my $percent = sprintf( "%.2f", ( int ( ( ($cov_found_count / $total_reads) * 10000 ) + 0.5 ) ) / 100 );
    $qc_stat->{'percent_reads_with_coverage'} = $percent;
}

# create kmer profile
foreach my $len (@kmers) {
    PipelineAWE::run_cmd("kmer-tool -l $len -p $proc -i $infile -t $format -o $out_prefix.kmer.$len.stats -f histo -r -d $run_dir");
}

# process stats into JSON struct
my $upload = {
    length_histogram => PipelineAWE::file_to_array("$seq_out.lens"),
    gc_histogram     => PipelineAWE::file_to_array("$seq_out.gcs")
};
my $qc = {
    drisee     => get_drisee($d_stats, $qc_stat),
    bp_profile => get_nucleo($c_stats),
    kmer       => {}
};
foreach my $len (@kmers) {
    $qc->{"kmer"}->{$len."_mer"} = get_kmer("$out_prefix.kmer.$len.stats", $len);
}

# output stats
PipelineAWE::print_json($seq_out, $upload);
PipelineAWE::print_json($qc_out, $qc);

# get drisee info
my $drisee_summary_stats = {
    drisee_input_seqs => 1,
    drisee_processed_bins => 1,
    drisee_processed_seqs => 1,
    drisee_score => 1
};
if (-s $d_info) {
    my @bin_stats = `tail -4 $d_info`;
    chomp @bin_stats;
    foreach my $line (@bin_stats) {
        my ($key, $val) = split('\t', $line);
        $key =~ s/\s+/_/g;
        $key = lc($key);
        unless ($key =~ /^drisee/i) {
            $key = 'drisee_'.$key
        }
        if (exists $drisee_summary_stats->{$key}) {
            $qc_stat->{$key} = $val;
        }
    }
}

# output attributes
PipelineAWE::create_attr($seq_out.'.json', $seq_stats, {assembled => $a_text, data_type => "statistics", file_format => "json"});
PipelineAWE::create_attr($qc_out.'.json', $qc_stat, {assembled => $a_text, data_type => "statistics", file_format => "json"});
PipelineAWE::create_attr($a_file.'.json', $qc_stat, {assembled => $a_text, data_type => "coverage", file_format => "text"});

exit 0;

sub get_usage {
    return "USAGE: awe_qc.pl -input=<input file> -format=<sequence format> -out_prefix=<output prefix> [-proc=<number of threads, default 8>, -kmers=<kmer list, default 6,15>, -assembled=<0 or 1, default 0>]\noutputs: \${out_prefix}.drisee.stats, \${out_prefix}.drisee.info, \${out_prefix}.consensus.stats, \${out_prefix}.kmer.\$len.stats, \${out_prefix}.assembly.coverage, \${out_prefix}.assembly.coverage.stats\n";
}

sub get_drisee {
    my ($dfile, $stats) = @_;
    
    my $bp_set = ['A', 'T', 'C', 'G', 'N', 'InDel'];
    my $drisee = PipelineAWE::file_to_array($dfile);
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
    my $nuc  = PipelineAWE::file_to_array($nfile);
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
    my $kmer = PipelineAWE::file_to_array($kfile);
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
