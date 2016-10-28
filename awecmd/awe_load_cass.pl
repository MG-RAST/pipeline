#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
use Cwd;
umask 000;

my $job_id  = "";
my $md5     = "";
my $lca     = "";
my $api_url = "";
my $ann_ver = 1;
my $chunk   = 5000;
my $help    = 0;
my $options = GetOptions (
		"job=s"     => \$job_id,
		"md5=s"     => \$md5,
		"lca=s"     => \$lca,
		"ann_ver=s" => \$ann_ver,
		"api_url=s" => \$api_url,
		"help!"     => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($md5)==0){
    PipelineAWE::logger('error', "md5 file was not specified");
    exit 1;
}elsif (! -e $md5){
    PipelineAWE::logger('error', "md5 file [$md5] does not exist");
    exit 1;
}elsif (length($lca)==0){
    PipelineAWE::logger('error', "lca file was not specified");
    exit 1;
}elsif (! -e $lca){
    PipelineAWE::logger('error', "lca file [$lca] does not exist");
    exit 1;
}elsif (length($job_id)==0){
    PipelineAWE::logger('error', "job ID is required");
    exit 1;
}

# get api variable
my $api_key = $ENV{'MGRAST_WEBKEY'} || undef;

### update attribute stats
my $this_attr = PipelineAWE::get_userattr();
my $mgid = $this_attr->{id};

my $files = {
    md5 => $md5,
    lca => $lca
};
my $start = {
    metagenome_id => $mgid,
    ann_ver       => $ann_ver,
    action        => "start"
};
my $load = {
    metagenome_id => $mgid,
    ann_ver       => $ann_ver,
    action        => "load"
};
my $end = {
    metagenome_id => $mgid,
    ann_ver       => $ann_ver,
    action        => "end"
};

foreach my $type (("md5", "lca")) {
    my $infile = $files->{$type};
    $start->{type} = $type;
    $load->{type}  = $type;
    $end->{type}   = $type;
    
    $load->{data} = [];
    $end->{count} = 0;
    
    PipelineAWE::logger('info', "Set job $type table as loading");
    PipelineAWE::obj_from_url($api_url."/job/abundance", $api_key, $start);
    
    my $count = 0;
    my $total = 0;
    PipelineAWE::logger('info', "Loading to job $type table");
    open(INFILE, "<$infile") || die "Can't open file $infile!\n";
    while(my $line = <INFILE>) {
        chomp $line;
        my @parts = split(/\t/, $line);
        $count += 1;
        $total += 1;
        push @{$load->{data}}, [ $parts[0], int($parts[1]), toFloat($parts[2]), toFloat($parts[3]), toFloat($parts[4]), int($parts[5]), int($parts[6]) ];
        if ($count == $chunk) {
            PipelineAWE::obj_from_url($api_url."/job/abundance", $api_key, $load);
            $count = 0;
            $load->{data} = [];
        }
    }
    close(INFILE);
    if ($count > 0) {
        PipelineAWE::obj_from_url($api_url."/job/abundance", $api_key, $load);
    }
    
    $end->{count} = $total;
    PipelineAWE::logger('info', "Set job $type table as done: $total rows loaded");
    PipelineAWE::obj_from_url($api_url."/job/abundance", $api_key, $end);
}

exit 0;

sub toFloat {
    my ($x) = @_;
    return $x * 1.0;
}

