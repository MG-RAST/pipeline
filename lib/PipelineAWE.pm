package PipelineAWE;

use strict;
use warnings;
no warnings('once');

use Data::Dumper;

sub run_cmd {
    my ($cmd, $shell) = @_;
    
    my @parts = split(/ /, $cmd);
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

1;
