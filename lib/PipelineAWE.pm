package PipelineAWE;

use strict;
use warnings;
no warnings('once');

use Data::Dumper;

sub run_cmd {
    my ($cmd) = @_;
    my $parts = split(/ /, $cmd);
    system($parts);
    if ($? != 0) {
        print STDERR "ERROR: ".$parts[0]." returns value $?\n";
        exit $?;
    }
}

1;
