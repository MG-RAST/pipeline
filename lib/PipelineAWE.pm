package PipelineAWE;

use strict;
use warnings;
no warnings('once');

use JSON;
use Data::Dumper;

sub run_cmd {
    my ($cmd, $shell) = @_;
    
    my $status = undef;
    my @parts  = split(/ /, $cmd);
    print STDOUT $cmd."\n";
    
    if ($shell) {
        $status = system($cmd);
    } else {
        $status = system(@parts);
    }
    
    if ($status != 0) {
        print STDERR "ERROR: ".$parts[0]." returns value $status\n";
        exit $status;
    }
}

sub create_attr {
    my ($name, $stats, $other) = @_;
    
    my $attr;
    my $json = JSON->new;
    $json = $json->utf8();
    $json->max_size(0);
    $json->allow_nonref;
    
    open(IN, "<userattr.json") or die "Couldn't open file: $!";
    $attr = $json->decode(join("", <IN>)); 
    close(IN);
    
    if ($stats && ref($stats)) {
        $attr->{statistics} = $stats;
    }
    if ($other && ref($other)) {
        foreach my $key (keys %$other) {
            $attr->{$key} = $other->{$key};
        }
    }
    
    open(OUT, ">$name") or die "Couldn't open file: $!";
    print OUT $json->encode($attr);
    close(OUT);
}

sub get_seq_stats {
    my ($file, $type, $fast) = @_;
    
    unless ($file && (-s $file)) {
        return {};
    }
    
    my $cmd = "seq_length_stats.py -i $file";
    if ($type) {
        $cmd .= " -t $type";
    }
    if ($fast) {
        $cmd .= " -f"
    }
    my @out = `$cmd`;
    chomp @out;
    
    my $stats = {};
    foreach my $line (@out) {
        if ($line =~ /^\[error\]/) {
            print STDERR $line."\n";
            exit 1;
        }
        my ($k, $v) = split(/\t/, $line);
        $stats->{$k} = $v;
    }
    return $stats;
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


1;
