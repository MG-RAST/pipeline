#!/usr/bin/env perl

use strict;
use warnings; 

use Getopt::Long;

use Pipeline_Conf;
use Data::Dumper;

use strict;

# read in parameters
my $user_dir        = '';
my $upload_dir      = '';
my $upload_filename = '';
my $demultiplex     = 0;
my $partitioned     = 0;

GetOptions ( 
	     'user_dir=s'        => \$user_dir,
	     'upload_dir=s'      => \$upload_dir,
	     'upload_filename=s' => \$upload_filename,
	     'demultiplex:i'     => \$demultiplex,
	     'partitioned:i'     => \$partitioned,
	   );

my $usage = "usage:  $0 --user_dir <user_dir> --upload_dir <upload_dir> --upload_filename <upload_filename> [--demultiplex 1] [--partitioned 1]\n";

my $base_dir = $Pipeline_Conf::incoming_dir;

if ( ! ($user_dir and $upload_dir and $upload_filename) ) {
    print $usage;
    exit;
}

if ( ! -d "$base_dir/$user_dir" ) {
    die "$usage\ncould not find directory user_dir '$base_dir/$user_dir': $!";
}

if ( ! -d "$base_dir/$user_dir/$upload_dir" ) {
    die "$usage\ncould not find directory upload_dir '$base_dir/$user_dir/$upload_dir': $!";
}

if ( ! $partitioned ) {
    # partitioned files are named with an index suffix, like large.fasta.0, large.fasta.1, etc. the file large.fasta will not be found
    if ( ! -s "$base_dir/$user_dir/$upload_dir/$upload_filename" ) {
	die "$usage\ncould not find file upload_filename '$base_dir/$user_dir/$upload_dir/$upload_filename': $!";
    }
}


my $options = "--user_dir $user_dir --upload_dir $upload_dir --upload_filename $upload_filename";

if ( $demultiplex ) {
    $options .= " --demultiplex $demultiplex";
}

if ( $partitioned ) {
    $options .= " --partitioned $partitioned";
}

my $output;
eval {
    $output = `echo 'preprocess.pl $options' | qsub -q fast -j oe -N preprocess -l walltime=60:00:00 -m n -o $base_dir/$user_dir/$upload_dir`;
};

if ($@) {
    print STDERR "could not queue preprocess on torque: $@, $output\npreproces.pl failed for file '$base_dir/$user_dir/$upload_dir/$upload_filename' run with options '$options'\n";
}
 
