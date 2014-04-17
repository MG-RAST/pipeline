#!/usr/bin/env perl 

use strict;
use warnings;
no warnings('once');

use Getopt::Long;
use File::Copy;
use File::Basename;
use POSIX qw(strftime);
umask 000;

my $index_ids = {
    'a_thaliana'     => 201,
    'b_taurus'       => 202,
    'd_melanogaster' => 203,
    'e_coli'         => 204,
    'h_sapiens'      => 205,
    'm_musculus'     => 206,
    's_scrofa'       => 207,
};

# options
my $fasta_file = "";
my $run_bowtie = 1;
my $index   = "";
my $threads = 1;
my $help    = "";
my $options = GetOptions (
        "input=s"   => \$fasta_file,
		"output=s"  => \$final_output,
		"index=s"   => \$index,
		"threads=i" => \$threads,
		"bowtie=i"  => \$run_bowtie,
		"help"      => \$help
);

if ($help){
    print_usage();
    exit 0;
}elsif (length($fasta_file)==0){
    print "ERROR: An input file was not specified.\n";
    print_usage();
    exit __LINE__;  #use line number as exit code
}elsif (! -e $fasta_file){
    print "ERROR: The input sequence file [$fasta_file] does not exist.\n";
    print_usage();
    exit __LINE__;   
}

if ($run_bowtie == 0) {
  system("cp $fasta_file $final_output") == 0 or exit __LINE__;
  exit (0);
}

# check indexes
my @indexes = split(/,/, $index);
for my $i (@indexes) {
  unless ( defined $index_ids->{$i} ) {
    print "undefined index name: $i\n";
    exit __LINE__
  }
}

my $index_dir = "";
if ($ENV{'REFDBPATH'}) {
  $index_dir = "$ENV{'REFDBPATH'}";
} else {
  $index_dir = ".";
}

my $input_file = $fasta_file;
for my $index_name (@indexes) {
  my $unaligned = $index_ids->{$index_name}.".".$index_name.".passed.fna";
  print "bowtie2 -f --reorder -p $threads --un $unaligned -x $index_dir/$index_name -U $input_file"
  system("bowtie2 -f --reorder -p $threads --un $unaligned -x $index_dir/$index_name -U $input_file > /dev/null") == 0 or exit __LINE__;
  $input_file = $unaligned;
}

system("mv $input_file $final_output") == 0 or exit __LINE__;

exit(0);


sub print_usage{
    print "USAGE: awe_bowtie_screen.pl -input=<input_fasta> -output=<final_output> -index=<bowtie_indexes, separated by ,> [-job=<job number> -threads=<number of threads>]\n";
}
