#!/usr/bin/env perl 

use strict;
use warnings;
no warnings('once');

use Getopt::Long;
use File::Copy;
use File::Basename;
use POSIX qw(strftime);
umask 000;

my $stage_name  = "screen";
my $stage_id  = 299;
my $revision  = "0";
my $runcmd    = "bowtie";

my $index_ids = { a_thaliana            => 201,
			b_taurus              => 202,
			d_melanogaster_fb5_22 => 203,
			e_coli                => 204,
			h_sapiens_asm         => 205,
			m_musculus_ncbi37     => 206,
			's_scrofa_ncbi10.2'   => 207,
		      };

# options
my $job_num    = "000";
my $input_fasta = "input.fasta";
my $fasta_file = "";
my $index      = "";
my $threads    = "";
my $ver     = "";
my $help    = "";
my $final_output = "";
my $options = GetOptions ("job=i"        => \$job_num,
			  "input=s"      => \$fasta_file,
			  "output=s"     => \$final_output,
			  "indexes=s"    => \$index,
			  "threads=i"    => \$threads,
			  "version"      => \$ver,
			  "help"         => \$help,
			 );

unless ( $threads ) {
  $threads = 1;
}

unless (-s $fasta_file) {
  print "inputfile: $fasta_file does not exist or is empty\n";
  print_usage();
  exit __LINE__;
}

# update jobcache stage status

#my $hostname    = `hostname`;
#chomp $hostname;

system("mkdir -p sort_dir") == 0 or exit (__LINE__);

my $input_file  = "";

system("cp $fasta_file $input_fasta > cp.out 2>&1") == 0 or exit __LINE__;

# deal with bowtie only being able to handle 1024 bp read
system("seqUtil --bowtie_truncate -i $input_fasta -o bowtie.input >> sequtil.out 2>&1") == 0 or  exit __LINE__;
system("diff $input_fasta bowtie.input > input.diff");
if ( -s "input.diff" > 0 ) {
  system("seqUtil --sortbyid -t sort_dir -i $input_fasta -o input.sorted >> sequtil.out 2>&1") == 0 or exit __LINE__;
  $input_file = "bowtie.input";
} else {
  $input_file = "$input_fasta";
  unlink("bowtie.input");
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

for my $index_name (@indexes) {
  my $unaligned_reads = $index_ids->{$index_name}.".".$stage_name.".".$index_name.".passed.fna";
  my $aligned_reads   = $index_ids->{$index_name}.".".$stage_name.".".$index_name.".removed.fna";
  my $aligned_ids     = $index_ids->{$index_name}.".".$stage_name.".".$index_name.".removed.ids";
  my $info_file       = $index_ids->{$index_name}.".".$stage_name.".".$index_name.".info";
  my $out_file        = $index_ids->{$index_name}.".".$stage_name.".".$index_name.".out";

  open(INFO, ">".$info_file);
  print INFO "$runcmd --suppress 5,6 -p $threads -t $index_name\n";
  close(INFO);

  system("$runcmd --suppress 5,6 -p $threads --al $aligned_reads --un $unaligned_reads -f -t $index_dir/$index_name $input_file > $aligned_ids 2> $out_file") == 0 or exit __LINE__;

  unless (-e $aligned_reads ) {
    unlink($aligned_ids);
  }
  $input_file = $unaligned_reads;
}

my $passed_seq = $stage_id.".".$stage_name.".passed.fna";

if ((-e "bowtie.input") and (-e "input.sorted")) {
  system("cat *.removed.ids | cut -f1 | sort -u > removed.ids");
  system("seqUtil --remove_seqs -i input.sorted -o $passed_seq -l removed.ids >> sequtil.out 2>&1") == 0 or exit __LINE__;
} else {
  system("cp $input_file $passed_seq >> cp.out 2>&1") == 0 or exit __LINE__;
}

if (length($final_output) > 0) {
    system("mv $passed_seq $final_output") == 0 or exit __LINE__;
}

system("rm $input_file");

exit(0);


sub print_usage{
    print "USAGE: awe_bowtie_screen.pl -input=<input_fasta> -output=<final_output> -index=<bowtie_indexes, separated by ,> [-job=<job number> -threads=<number of threads>]\n";
}

