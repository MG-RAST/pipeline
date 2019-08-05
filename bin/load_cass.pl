#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use JSON;
use LWP::UserAgent;
use HTTP::Request;
use Getopt::Long;
use Cwd;
umask 000;

my $json = JSON->new;
$json = $json->utf8();
$json->max_size(0);
$json->allow_nonref;

my $agent = LWP::UserAgent->new();
$agent->env_proxy;
$agent->timeout(3600);

my $post_attempt = 0;

my $mgid    = "";
my $infile  = "";
my $type    = "";
my $api_url = "";
my $ann_ver = 1;
my $chunk   = 5000;
my $verbose = 0;
my $help    = 0;
my %types   = {
    'md5' => 1,
    'lca' => 1
};
my $options = GetOptions (
		"mgid=s"    => \$mgid,
		"file=s"    => \$infile,
		"type=s"    => \$type,
		"ann_ver=s" => \$ann_ver,
		"api_url=s" => \$api_url,
        "verbose=s" => \$verbose,
		"help!"     => \$help
);

if ($help) {
    print get_usage();
    exit 0;
} elsif (length($infile) == 0) {
    print STDERR "[error] abundance file was not specified";
    exit 1;
} elsif (! -e $infile) {
    print STDERR "[error] abundance file [$infile] does not exist";
    exit 1;
} elsif (length($type) == 0) {
    print STDERR "[error] abundance type was not specified";
    exit 1;
} elsif (! exists($types{$type})) {
    print STDERR "[error] abundance type [$type] is not valid";
    exit 1;
} elsif (length($mgid) == 0) {
    print STDERR "[error] metagenome ID is required";
    exit 1;
}

# get api variable
my $api_key = $ENV{'MGRAST_WEBKEY'} || undef;

my $start = {
    metagenome_id => $mgid,
    type          => $type,
    ann_ver       => $ann_ver,
    action        => "start"
};
my $load = {
    metagenome_id => $mgid,
    type          => $type,
    ann_ver       => $ann_ver,
    action        => "load",
    data          => []
};
my $end = {
    metagenome_id => $mgid,
    type          => $type,
    ann_ver       => $ann_ver,
    action        => "end",
    count         => 0
};

if ($verbose) {
    print STDOUT "Set job $type table as loading\n";
}
my $status = post_data($api_url."/job/abundance", $api_key, $start);
unless (defined($status->{status}) && ($status->{status} eq "empty $type")) {
    print STDERR "[error] unable to set $type table as loading";
    exit 1;
}
    
my $count = 0;
my $total = 0;
if ($verbose) {
    print STDOUT "Loading to job $type table\n";
}
open(INFILE, "<$infile") || die "Can't open file $infile!\n";
while(my $line = <INFILE>) {
    chomp $line;
    my @parts = split(/\t/, $line);
    $count += 1;
    $total += 1;
    push @{$load->{data}}, [ $parts[0], int($parts[1]), toFloat($parts[2]), toFloat($parts[3]), toFloat($parts[4]), int($parts[5]), int($parts[6]) ];
    if ($count == $chunk) {
        $status = post_data($api_url."/job/abundance", $api_key, $load);
        unless (defined($status->{loaded}) && ($status->{loaded} == $total)) {
            print STDERR "[error] $type table has ".$status->{loaded}." rows. $total were sent\n";
            exit 1;
        }
        $count = 0;
        $load->{data} = [];
    }
}
close(INFILE);
if ($count > 0) {
    post_data($api_url."/job/abundance", $api_key, $load);
}
    
$end->{count} = $total;
if ($verbose) {
    print STDOUT "Set job $type table as done: $total rows loaded";
}
$status = post_data($api_url."/job/abundance", $api_key, $end);
unless (defined($status->{status}) && ($status->{status} eq "done $type")) {
    print STDERR "[error] unable to set $type table as completed";
    exit 1;
}

exit 0;

sub toFloat {
    my ($x) = @_;
    return $x * 1.0;
}

sub post_data {
    my ($url, $token, $data) = @_;
    
    my $req = HTTP::Request->new(POST => $url);
    $req->header('content-type' => 'application/json');
    if ($token) {
        $req->header('authorization' => "mgrast $token");
    }
    $req->content($json->encode($data));
    
    my $resp = $agent->request($req);
    
    # try 3 times
    if (($post_attempt < 3) && (! $resp->is_success)) {
        $post_attempt += 1;
        post_data($url, $token, $data);
    }
    
    # success or gave up
    $post_attempt = 0;
    my $content = undef;
    eval {
        $content = $json->decode( $resp->decoded_content );
    };
    if ($@ || (! ref($content))) {
        print STDERR "[error] ".$resp->decoded_content;
        exit 1;
    } elsif ($content->{'ERROR'}) {
        print STDERR "[error] from $url: ".$content->{'ERROR'};
        exit 1;
    } elsif ($content->{'error'}) {
        print STDERR "[error] from $url: ".$content->{'error'};
        exit 1;
    } else {
        return $content;
    }
}

sub get_usage {
    return "USAGE: mgrast_load_cass.pl -mgid=<metagenome identifier> -file=<abundance file> -type=<abundance type: md5 or lca> -api_url <mgrast api url> -ann_ver <m5nr annotation version #>\n";
}
