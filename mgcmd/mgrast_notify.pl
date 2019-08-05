#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
umask 000;

# globals
my $site = 'https://www.mg-rast.org';
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

if ($help) {
    print get_usage();
    exit 0;
} elsif (length($user) == 0) {
    PipelineAWE::logger('error', "user ID is required");
    exit 1;
}

unless ($api_url) {
    $api_url = $PipelineAWE::default_api;
}

# get api variable
my $api_key = $ENV{'MGRAST_WEBKEY'} || undef;

# get info
my $job_info  = PipelineAWE::get_userattr();
my $job_name  = $job_info->{name};
my $proj_name = $job_info->{project_name};

# email owner on completion
my $subject  = "MG-RAST Job Completed";
my $body_txt = qq(
Your submitted annotation job $job_name belonging to study $proj_name has completed.

Log in to MG-RAST ($site) to view your results. Your completed data is available through the My Studies section on your My Data page.
PLEASE NOTE: Your data has NOT been made public and ONLY you can currently view the data and results.
If you wish to publicly share the link to your results, you will need to make the data public yourself. This is needed even if you selected that the data is going to be made public immediately after completion.
This is an automated message. Please contact help\@mg-rast.org if you have any questions or concerns.
);

PipelineAWE::post_data($api_url."/user/".$user."/notify", $api_key, {'subject' => $subject, 'body' => $body_txt});

exit 0;

sub get_usage {
    return "USAGE: mgrast_notify.pl -user=<user identifier>\n";
}
