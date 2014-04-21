package PipelineAWE;

use strict;
use warnings;
no warnings('once');

use Data::Dumper;

sub run_cmd{
    my ($cmd) = @_;
    my $run = (split(/ /, $cmd))[0];
    system($cmd);
    if ($? != 0) {
        print "ERROR: $run returns value $?\n";
        exit $?;
    }
}

1;
