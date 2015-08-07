#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use PipelineAWE;
use Getopt::Long;
umask 000;

# globals
my $mg_link = 'http://metagenomics.anl.gov/linkin.cgi?metagenome=';
my $api_url = "";
my $user = "";
my $mgid = "";
my $help = 0;

my $options = GetOptions (
    "api_url=s" => \$api_url,
    "user=s" => \$user,
    "mgid=s" => \$mgid,
    "help!"  => \$help
);

if ($help){
    print get_usage();
    exit 0;
}elsif (length($user)==0){
    print STDERR "ERROR: A user ID is required.\n";
    print STDERR get_usage();
    exit 1;
}elsif (length($mgid)==0){
    print STDERR "ERROR: A MG-RAST ID is required.\n";
    print STDERR get_usage();
    exit 1;
}

# get api variable
my $api_key = $ENV{'MGRAST_WEBKEY'} || undef;

# get info
my $user_attr = PipelineAWE::get_userattr();
my $user_info = PipelineAWE::get_user_info($user, $api_url, $api_key);

# email owner on completion
my $link = $mgid;
$link =~ s/^mgm(.*)/$1/;
$link = $mg_link.$link;
my $name = $user_attr->{name} ? " for ".$user_attr->{name} : "";
my $body_txt = "The annotation job that you submitted$name has completed.\n\n".
               "You can view you job here:\n$link\n\n".
               "PLEASE NOTE: Your data has NOT been made public and ONLY you can currently view the data and results.\n".
		"If you wish to publicly share the link to your results, you will need to make the data public yourself. This is needed even if you selected that the data is going to be made public immediately after completion.\n".
               'This is an automated message. Please contact mg-rast@mcs.anl.gov if you have any questions or concerns.';
PipelineAWE::send_mail($body_txt, "MG-RAST Job Completed", $user_info);

exit 0;

sub get_usage {
    return "USAGE: awe_notify.pl -user=<user identifier> -mgid=<mgrast identifier>\n";
}
