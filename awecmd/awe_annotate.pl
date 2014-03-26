#!/usr/bin/env perl 

#this script does memcache search to post process the blat output for both aa and rna, and generate files ready for loaddb

use strict;
use warnings;
no warnings('once');

use Getopt::Long;
use File::Copy;
use File::Basename;
use POSIX qw(strftime);
use Cwd;
umask 000;

my $min_gene_size = 1024;
my $mem_host      = "localhost:11211";
my $mem_key       = '_ach';
my $sort_mem      = 10;
my $procs         = 4;
my $max_seq       = 500000;
my $ver_db=7;
my $stage_name="sims";
my $stage_id = 700;
my $revision = "0";

my $run_dir = getcwd();
my $sort_dir = getcwd();

my $out_prefix = $stage_id;

# options
my $job_id = "";
my $raw_input="";
my $aa_sims  = "";
my $rna_sims = "";
my $clust_aa = "";
my $map_rna = "";
my $assembled = 0; 

my $options = GetOptions ("job=s"    => \$job_id,
			  "raw=s"    => \$raw_input,
			  "aa_sims=s"  => \$aa_sims,
			  "rna_sims=s"   => \$rna_sims,
			  "clust_aa=s"   => \$clust_aa,
			  "map_rna=s"    => \$map_rna,
 			  "out_prefix=s" => \$out_prefix,
			  "mem_host=s" => \$mem_host,
			  "mem_key=s" => \$mem_key,
			  "nr_ver=s" => \$ver_db,
			  "assembled=i"  => \$assembled
			 );

my $prefix_aa = $out_prefix.".aa";
my $prefix_rna = $out_prefix.".rna";

if ($job_id eq "") {
    print  "Error: job is a required parameter\n";
    print_usage();
    exit __LINE__;
}


unless (-s $raw_input) {
    print  "Error: raw input file: [$raw_input] does not exist or is size zero\n";
    print_usage();
    exit __LINE__;
}

my $input_file_str = "--fasta $raw_input ";


unless (-s $aa_sims || -s $rna_sims) {
    print  "Error: either -aa_sims (\'$aa_sims\') or -rna_sims (\'$rna_sims\') should be non-empty\n";
    print_usage();
    exit __LINE__;
}

if (-s $aa_sims) {
  $input_file_str .= "--aa_sims_file $aa_sims ";
}
if (-s $rna_sims) {
  $input_file_str .= "--rna_sims_file $rna_sims ";
}

if (-s $clust_aa) {
  $input_file_str .= "--clust_aa $clust_aa ";  
}
if (-s $map_rna) {
  $input_file_str .= "--map_rna $map_rna ";
}

my $assembly_abun_opt = "";
my $cov_found_count = 0;
my $total_reads = 0;
if($assembled == 1) {
  my $abundance_file = "$job_id.abundance";
  print "Printing out assembly abundance to file: $abundance_file\n";
  open ABUN, ">$abundance_file" || exit __LINE__;
  open SEQS, $raw_input || exit __LINE__;
  while(my $line=<SEQS>) {
    chomp $line;
    if($line =~ /^>(\S+\_\[cov=(\S+)\]\S*).*$/) {
      my $seq = $1;
      my $abun = $2;
      print ABUN "$seq\t$abun\n";
      $cov_found_count++;
      $total_reads++;
    } elsif($line =~ /^>(\S+).*$/) {
      my $seq = $1;
      print ABUN "$seq\t1\n";
      $total_reads++;
    }
  }
  close SEQS;
  close ABUN;
  $assembly_abun_opt = "--abun_file $abundance_file";

  open OUT, ">$job_id.700.annotation.coverage.summary" || exit __LINE__;
  my $percent = sprintf( "%.2f", ( int ( ( ($cov_found_count/$total_reads) * 10000 ) + 0.5 ) ) / 100 );
  print OUT "Percentage_of_reads_with_coverage_info:\t$percent\n";
  close OUT;
} else {
  system("touch $job_id.700.annotation.coverage.summary 2>&1") == 0 or exit __LINE__;
}

print "input_file_str=".$input_file_str."\n";

system("sims2annotation_less_sorting --job_id $job_id $input_file_str --sort_dir $sort_dir --run_dir $run_dir --prefix $out_prefix --ver_db $ver_db --mem_host $mem_host --mem_key $mem_key --procs $procs $assembly_abun_opt >> sims2annotation.out 2>&1") == 0 or exit __LINE__;

print "Finished $stage_name on job $job_id\n";

exit(0);

sub print_usage{
    print "USAGE: awe_annotate.pl -job=<job identifier>
                                  -raw=<raw input fasta or fastq>
                                  -aa_sims=<input aa sims file>
				  -rna_sims=<input rna sims file>
				  -clust_aa=<aa clust output>
				  -map_rna=<rna clust map>
				  -mem_host=<memcache host>
				  -nr_ver=<nr db version>
				  [-out_prefix=<prefix for output files>]
				  [-assembled=<0 or 1, default 0]\n";
}
