#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
umask 000;

my $index_ids = {
    'a_thaliana'     => 201,
    'b_taurus'       => 202,
    'd_melanogaster' => 203,
    'e_coli'         => 204,
    'h_sapiens'      => 205,
    'm_musculus'     => 206,
    's_scrofa'       => 207,
    'r_norvegicus'   => 208
};

# options
my $fasta       = "";
my $output      = "";
my $run_bowtie  = 1;
my $index       = "";
my $proc        = 8;
my $help        = 0;
my $do_not_create_index_files = 0;

my $options = GetOptions (
        "input=s"  => \$fasta,
		"output=s" => \$output,
		"index=s"  => \$index,
		"proc=i"   => \$proc,
		"bowtie=i" => \$run_bowtie,
        "no-shock" => \$do_not_create_index_files,
		"help!"    => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($fasta)==0){
    PipelineAWE::logger('error', "input file was not specified");
    exit 1;
}elsif (length($output)==0){
    PipelineAWE::logger('error', "output file was not specified");
    exit 1;
}elsif (! -e $fasta){
    PipelineAWE::logger('error', "input sequence file [$fasta] does not exist");
    exit 1;
}

# get api variable
my $api_key = $ENV{'MGRAST_WEBKEY'} || undef;

# skip it
if ($run_bowtie == 0) {
    PipelineAWE::run_cmd("mv $fasta $output");
}
# run it
else {
    # check indexes
    my @indexes = split(/,/, $index);
    if (scalar(@indexes) == 0) {
        PipelineAWE::logger('error', "missing index");
        exit 1;
    }
    for my $i (@indexes) {
        unless ( defined $index_ids->{$i} ) {
            PipelineAWE::logger('error', "undefined index name: $i");
            exit 1;
        }
    }

    # get index dir
    my $index_dir = ".";
    if ($ENV{'REFDBPATH'}) {
        $index_dir = "$ENV{'REFDBPATH'}";
    }
    
    # truncate input to 1000 bp
    my $input_file = $fasta.'.trunc';
    PipelineAWE::run_cmd("seqUtil --truncate 1000 -i $fasta -o $input_file");

    # run bowtie2
    my $tmp_input_var = $input_file;
    for my $index_name (@indexes) {
        my $unaligned = $index_ids->{$index_name}.".".$index_name.".passed.fna";
        # 'reorder' option outputs sequences in same order as input file
        PipelineAWE::run_cmd("bowtie2 -f --reorder -p $proc --un $unaligned -x $index_dir/$index_name -U $tmp_input_var > /dev/null", 1);
        $tmp_input_var = $unaligned;
    }
    PipelineAWE::run_cmd("mv $tmp_input_var $output");
    
    # die if nothing passed
    if (-z $output) {
        # send email
        if ($api_key) {
            my $user_attr = PipelineAWE::get_userattr();
            my $job_name  = $user_attr->{name};
            my $job_id    = $user_attr->{id};
            my $proj_name = $user_attr->{project_name};
            my $subject   = "MG-RAST Job Failed";
            my $body_txt  = qq(
The annotation job that you submitted for $job_name ($job_id) belonging to study $proj_name has failed.
No sequences passed our QC screening steps. Either your sequences were too short or your pipeline QC settings were to stringent.

This is an automated message.  Please contact help\@mg-rast.org if you have any questions or concerns.
);
            PipelineAWE::post_data($PipelineAWE::default_api."/user/".$user_attr->{owner}."/notify", $api_key, {'subject' => $subject, 'body' => $body_txt});
        }
        PipelineAWE::logger('error', "pipeline failed, no sequences passed bowtie screening, index=".$index);
        # exit failed-permanent
        exit 42;
    }
    
    # create subset record list
    # note: parent and child files in same order
    if (not $do_not_create_index_files ) {
      PipelineAWE::run_cmd("index_subset_seq.py -p $input_file -c $output -s -m 20");
      PipelineAWE::run_cmd("mv $output.index $output");
    }
  }

exit 0;

sub get_usage {
    return "USAGE: mgrast_bowtie_screen.pl -input=<input fasta> -output=<output fasta> -index=<bowtie indexes separated by ,> [-proc=<number of threads, default: 8>]\n";
}
