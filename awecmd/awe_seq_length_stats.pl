#!/usr/bin/env perl 

#input: .fna, .fasta, .fq, or .fastq 
#outputs: output.stats.txt

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use Digest::MD5;
umask 000;

# options
my $input_file = "";
my $input_json_file = "";
my $output_json_file = "";
my $type = "fasta";
my $help = "";
my $options = GetOptions ("input=s" => \$input_file,
                          "input_json=s" => \$input_json_file,
                          "output_json=s" => \$output_json_file,
                          "type=s" => \$type,
                          "help!" => \$help
                         );

# Validate input file path.
if ($help) {
    print_usage();
    exit 0;
} elsif (length($input_file)==0) {
    print STDERR "ERROR: An input file was not specified.\n";
    print_usage();
    exit 1;
} elsif (! -e $input_file) {
    print STDERR "ERROR: The input sequence file [$input_file] does not exist.\n";
    print_usage();
    exit 1;
}
if ($type ne 'fasta' && $type ne 'fastq') {
    print STDERR "ERROR: The file type must be fasta or fastq format (default is fasta).\n";
    print_usage();
    exit 1;
}

# Validate other input and output file paths.
my $data = PipelineAWE::read_json($input_json_file);

# Get file info if missing
if (! exists($data->{stats_info})) {
    my $format = "ASCII text";
    my $suffix = (split(/\./, $input_file))[-1];
    my $base   = (split(/\//, $input_file))[-1];
    my @stats  = stat($input_file);
    open my $fh, '<', $input_file;
    my $ctx = Digest::MD5->new;
    $ctx->addfile($fh);
    # empty file
    if ($stats[7] == 0) {
        $format = "empty file";
        $type = "none";
    }
    $data->{stats_info} = {
        type      => $format,
        suffix    => $suffix,
        file_type => $type,
        file_name => $base,
        file_size => $stats[7],
        checksum  => $ctx->hexdigest
    };
    close $fh;
}

# exit gracefully if empty
if ($data->{stats_info}{file_size} == 0) {
    if ($output_json_file eq "") {
        $output_json_file = "$input_file.out.json";
    }
    PipelineAWE::print_json($output_json_file, $data);
    exit 0;
}

# Run sequence stats analysis
my @error = ();
my @stats = `seq_length_stats.py -i $input_file -t $type -s 2>&1`;
chomp @stats;
foreach my $line (@stats) {
    if ($line =~ /^\[error\]\s+(.*)/) {
        push @error, "Error\t".$1;
    } else {
        my ($key, $value) = split(/\t/, $line);
        $data->{stats_info}{$key} = $value;
    }
}
if ((@error == 0) && (($data->{stats_info}{sequence_count} eq "0") || ($data->{stats_info}{bp_count} eq "0"))) {
    push @error, "Error\tFile contains no sequences";
}

if (@error == 0) {
    # sequence content guess
    my $seq_content = "";
    if ($type eq 'fastq') {
        $seq_content = 'DNA';
    } else {
        my $max_chars = 10000;
        my $seq = '';
        my $line;
        open(TMP, "<$input_file") or die "could not open file '$input_file': $!";
        while ( defined($line = <TMP>) ) {
            chomp $line;
            if ( $line =~ /^\s*$/ or $line =~ /^>/ ) {
                next;
            } else {
                $seq .= $line;
            }
            last if (length($seq) >= $max_chars);
        }
        close(TMP);

        $seq =~ tr/A-Z/a-z/;
        my %char_count = ('a' => 0, 'c' => 0, 'g' => 0, 't' => 0, 'n' => 0, 'x' => 0, '-' => 0);
        foreach my $char ( split('', $seq) ) {
            $char_count{$char} += 1;
        }
        
        # find fraction of a,c,g,t characters from total, not counting '-', 'N', 'X'
        my $bp_char = $char_count{a} + $char_count{c} + $char_count{g} + $char_count{t};
        my $n_char  = length($seq) - $char_count{n} - $char_count{x} - $char_count{'-'};
        my $fraction = $n_char ? $bp_char/$n_char : 0;

        # A high fraction of dashes could indicate a sequence alignment file
        my $dash_fraction = $char_count{'-'}/length($seq);

        if ( $fraction <= 0.6 ) {
            $seq_content = "protein";
        } elsif( $dash_fraction >= 0.05 ) {
            $seq_content = "sequence alignment";
        } else {
            $seq_content = "DNA";
        }
    }
    $data->{stats_info}{sequence_content} = $seq_content;

    # tech guess
    my $header  = `head -1 '$input_file'`;
    my $options = '-s '.$data->{stats_info}{sequence_count}.' -a '.$data->{stats_info}{average_length}.
                  ' -d '.$data->{stats_info}{standard_deviation_length}.' -m '.$data->{stats_info}{length_max};
    my $method  = `tech_guess -f '$header' $options 2>&1`;
    chomp $method;

    if ($method =~ /^\[error\]\s+(.*)/) {
        push @error, "Error\t".$1;
    } else {
        $data->{stats_info}{sequencing_method_guess} = $method;
    }

    # count unique ids
    my $unique_ids = 0;
    if ($type eq 'fasta') {
        $unique_ids = `grep '>' $input_file | cut -f1 -d' ' | sort -T . -S 2G -u | wc -l 2>&1`;
        chomp $unique_ids;
    }
    elsif ($type eq 'fastq') {
        $unique_ids = `awk '0 == (NR + 3) % 4' $input_file | cut -f1 -d' ' | sort -T . -S 2G -u | wc -l 2>&1`;
        chomp $unique_ids;
    }
    
    my $unique_id_num = int($unique_ids);
    if (($unique_ids ne $unique_id_num) || ($unique_ids == 0)) {
        push @error, "Error\tUnable to count unique ids";
    } else {
        $data->{stats_info}{unique_id_count} = $unique_ids;
    }
}

# errors?
if (@error > 0) {
    print STDOUT join("\n", @error)."\n";
    exit 1;
}

# output attributes with stats
$data->{data_type} = "sequence";
if ($output_json_file eq "") {
    $output_json_file = "$input_file.out.json";
}
PipelineAWE::print_json($output_json_file, $data);

exit 0;

sub print_usage {
    print "USAGE: awe_seq_length_stats.pl -input=<input fasta or fastq> [-input_json=<attr_filename>, -output_json=<attr_filename>, -type=<fasta or fastq (default is fasta)>]\n";
}

