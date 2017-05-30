#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
umask 000;

# globals
my $site = 'http://metagenomics.anl.gov';
my $api_url = "";
my $user = "";
my $mgid = "";
my $help = 0;

my $options = GetOptions (
    "api_url=s" => \$api_url,
    "user=s" => \$user,
    "mgid:s" => \$mgid,
    "help!"  => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($user)==0){
    PipelineAWE::logger('error', "user ID is required");
    exit 1;
}

# get api variable
my $api_key = $ENV{'MGRAST_WEBKEY'} || undef;

# get info
my $job_info  = PipelineAWE::get_userattr();
my $user_info = PipelineAWE::get_user_info($user, $api_url, $api_key);

# email owner on completion
my $body_txt = "Your submitted annotation job ".$job_info->{name}." belonging to study ".$job_info->{project_name}." has completed.\n\n".
               "Log in to MG-RAST ($site) to view your results. Your completed data is available through the 'My Studies' section on your 'My Data' page.\n".
               "PLEASE NOTE: Your data has NOT been made public and ONLY you can currently view the data and results.\n".
		"If you wish to publicly share the link to your results, you will need to make the data public yourself. This is needed even if you selected that the data is going to be made public immediately after completion.\n".
               'This is an automated message. Please contact mg-rast@mcs.anl.gov if you have any questions or concerns.';
PipelineAWE::send_mail($body_txt, "MG-RAST Job Completed", $user_info);

exit 0;

sub get_usage {
    return "USAGE: awe_notify.pl -user=<user identifier>\n";
}
