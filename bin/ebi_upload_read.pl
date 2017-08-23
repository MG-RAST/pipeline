#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use JSON;
use Net::FTP;
use File::Basename;
use IPC::Open2;
use Digest::MD5;
use IO::Tee;
use IO::Compress::Gzip qw(gzip $GzipError);
use Getopt::Long;
umask 000;

# options
my $input  = "";
my $output = "";   
my $updir  = "";
my $furl   = "webin.ebi.ac.uk";
my $user   = $ENV{'EBI_USER'} || undef;
my $pswd   = $ENV{'EBI_PASSWORD'} || undef;
my $trim   = 0;
my $help   = 0;
my $options = GetOptions (
        "input=s"  => \$input,
        "output=s" => \$output,
        "updir=s"  => \$updir,
        "furl=s"   => \$furl,
        "user=s"   => \$user,
        "pswd=s"   => \$pswd,
        "trim!"    => \$trim,
		"help!"    => \$help
);

if ($help) {
    print get_usage();
    exit 0;
} elsif (! -s $input) {
    print STDERR "input sequence file is missing";
    exit 1;
} elsif (length($output)==0) {
    print STDERR "output was not specified";
    exit 1;
} elsif (! $updir) {
    print STDERR "upload ftp dir is missing";
    exit 1;
}

# trim if requested
if ($trim) {
    
}

my $json = JSON->new;
$json = $json->utf8();
$json->max_size(0);
$json->allow_nonref;

# set ftp connection
my $ftp = Net::FTP->new($furl) or die "Cannot connect to $furl: $!";
$ftp->login($user, $pswd) or die "Cannot login using $user and $pswd. ", $ftp->message;
$ftp->mkdir($updir);
$ftp->cwd($updir);
$ftp->binary();

# open pipes
my ($md5read, $md5write, $ftpread, $ftpwrite);
open2($md5read, $md5write) or die "open2() md5 failed: $!";
open2($ftpread, $ftpwrite) or die "open2() ftp failed: $!";

# tie together writes
my $teewrite = IO::Tee->new($md5write, $ftpwrite);

# gzip file to writer
gzip $input => $teewrite or die "gzip failed: $GzipError\n";

# md5 from tee
my $ctx = Digest::MD5->new();
$ctx->addfile($md5read);
my $md5 = $ctx->digest;

# ftp from tee
my $ftpfile = basename($input).".gz";
$ftp->put($ftpread, $ftpfile);

# print output
my $data = {
    "path" => $updir."/".$ftpfile,
    "md5" => $md5
};
print_json($output, $data);

exit 0;

sub get_usage {
    return "USAGE: ebi_upload_read.pl -input=<sequence file> -output=<output json file> -updir=<ftp upload dir> -furl=<ebi ftp url> -user=<ebi ftp user> -pswd=<ebi ftp password> -trim <boolean: run adapter trimmer>\n";
}

sub print_json {
    my ($file, $data) = @_;
    open(OUT, ">$file") or die "Couldn't open file: $!";
    print OUT $json->encode($data);
    close(OUT);
}
