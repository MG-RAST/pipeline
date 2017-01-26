package PipelineAWE;

use strict;
use warnings;
no warnings('once');

use JSON;
use POSIX;
use DateTime;
use DateTime::Format::ISO8601;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request;
use Net::SMTP;
use Capture::Tiny qw(:all);

our $post_attempt = 0;
our $debug = 1;
our $layout = '[%d] [%-5p] %m%n';
our $shock_api = "http://shock.metagenomics.anl.gov";
our $default_api = "http://api.metagenomics.anl.gov";
our $mg_email = '"Metagenomics Analysis Server" <mg-rast@mcs.anl.gov>';
our $mg_smtp = 'smtp.mcs.anl.gov';
our $global_attr = "userattr.json";
our $agent = LWP::UserAgent->new();
$agent->timeout(3600);
our $json = JSON->new;
$json = $json->utf8();
$json->max_size(0);
$json->allow_nonref;


######### Set logging  ##########

use Log::Log4perl qw(:easy);
if ($debug) {
    Log::Log4perl->easy_init({level => $DEBUG, layout => $layout});
} else {
    Log::Log4perl->easy_init({level => $INFO, layout => $layout});
}
our $logger = Log::Log4perl->get_logger();

######### Helper Functions ##########

sub logger {
    my ($type, $msg) = @_;
    # replace line breaks
    $msg =~ s/\n/, /g;
    # find logger channel
    if ($type eq 'debug') {
        $logger->debug($msg);
    } elsif ($type eq 'info') {
        $logger->info($msg);
    } elsif ($type eq 'warn') {
        $logger->warn($msg);
    } elsif ($type eq 'error') {
        $logger->error($msg);
    }
}

sub run_cmd {
    my ($cmd, $shell) = @_;
    my $status = undef;
    my $stderr = undef;
    my @parts  = split(/ /, $cmd);
    my $start  = time;
    logger('info', "exec: ".$cmd);
    eval {
        if ($shell) {
            (undef, $stderr, $status) = capture {
                system($cmd);
            };
        } else {
            (undef, $stderr, $status) = capture {
                system(@parts);
            };
        }
    };
    my $done = time;
    logger('info', "time: ".($done - $start)." secs");
    if ($@ || $status) {
        logger('error', "died running child process ".$parts[0]);
        logger('debug', $parts[0].": ".$@);
        if ($stderr) {
            logger('debug', "STDERR: ".$stderr);
        }
        if (defined($status) && ($status != 0)) {
            logger('error', $parts[0]." returns value $status");
            exit $status >> 8;
        }
        exit 1;
    }
}

sub file_to_array {
    my ($file) = @_;
    my $data = [];
    unless ($file && (-s $file)) {
        return $data;
    }
    open(FILE, "<$file") || return $data;
    while (my $line = <FILE>) {
        chomp $line;
        my @parts = split(/\t/, $line);
        push @$data, [ @parts ];
    }
    close(FILE);
    return $data;
}

sub obj_from_url {
    my ($url, $token) = @_;
    
    my @args = $token ? ('authorization', "mgrast $token") : ();
    my $result = $agent->get($url, @args);
    unless ($result) {
        logger('error', "unable to connect to $url");
        exit 1;
    }
    
    my $content = undef;
    eval {
        $content = $json->decode( $result->content );
    };
    if ($@ || (! ref($content))) {
        logger('error', $result->content);
        exit 1;
    } elsif ($content->{'ERROR'}) {
        logger('error', "from $url: ".$content->{'ERROR'});
        exit 1;
    } elsif ($content->{'error'}) {
        logger('error', "from $url: ".$content->{'error'});
        exit 1;
    } else {
        return $content;
    }
}

sub async_obj_from_url {
    my ($url, $token, $try) = @_;
    if ($try > 3) {
        logger('error', "async process for $url failed $try times");
        exit 1;
    }
    my @args = $token ? ('authorization', "mgrast $token") : ();
    my $content = undef;
    eval {
        my $result = $agent->get( $url."&retry=".$try, @args );
        $content = $json->decode( $result->content );
        if ($content->{ERROR}) {
            logger('error', "from $url: ".$content->{'ERROR'}." - trying again");
            $try += 1;
            $content = async_obj_from_url($url, $token, $try);
        }
        logger('info', "status: ".$content->{url});
        while ($content->{status} ne 'done') {
            sleep 120;
            $result = $agent->get( $content->{url} );
            $content = $json->decode( $result->content );
            if ($content->{ERROR}) {
                logger('error', "from $url: ".$content->{'ERROR'}." - trying again");
                $try += 1;
                $content = async_obj_from_url($url, $token, $try);
            } else {
                my $last = DateTime::Format::ISO8601->parse_datetime($content->{updated});
                my $now  = shock_time();
                my $diff = $now->subtract_datetime_absolute($last);
                if ($diff->seconds > 1800) {
                    logger('error', "async process for $url died - trying again");
                    $try += 1;
                    $content = async_obj_from_url($url, $token, $try);
                }
            }
        }
    };
    return $content;
}

sub shock_time {
    my $dt = undef;
    eval {
        my $result  = $agent->get($shock_api);
        my $content = $json->decode($result->content);
        $dt = DateTime::Format::ISO8601->parse_datetime($content->{server_time});
    };
    return $dt;
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
        logger('error', $resp->decoded_content);
        exit 1;
    } elsif ($content->{'ERROR'}) {
        logger('error', "from $url: ".$content->{'ERROR'});
        exit 1;
    } elsif ($content->{'error'}) {
        logger('error', "from $url: ".$content->{'error'});
        exit 1;
    } else {
        return $content;
    }
}

sub get_user_info {
    my ($user_id, $base_url, $key) = @_;
    unless ($base_url) {
        $base_url = $default_api;
    }
    my $get_url = $base_url.'/user/'.$user_id;
    return obj_from_url($get_url, $key);
}

sub send_mail {
    my ($body, $subject, $user_info) = @_;
    my $owner_name = ($user_info->{firstname} || "")." ".($user_info->{lastname} || "");
    if ($user_info->{email}) {
        my $smtp = Net::SMTP->new($mg_smtp, Hello => $mg_smtp);
        my $receiver = "\"$owner_name\" <".$user_info->{email}.">";
        $smtp->mail('mg-rast');
        my @data = (
            "To: $receiver\n",
            "From: $mg_email\n",
            "Date: ".strftime("%a, %d %b %Y %H:%M:%S %z", localtime)."\n",
            "Subject: $subject\n\n",
            $body
        );
        $smtp->mail('mg-rast');
        if ($smtp->to($receiver)) {
            $smtp->data(@data);
        } else {
            logger('error', $smtp->message());
        }
        $smtp->quit;
    }
}

######### JSON Functions ##########

sub print_json {
    my ($file, $data) = @_;
    open(OUT, ">$file") or die "Couldn't open file: $!";
    print OUT $json->encode($data);
    close(OUT);
}

sub read_json {
    my ($file) = @_;
    my $data = {};
    if (-s $file) {
        open(IN, "<$file") or die "Couldn't open file: $!";
        $data = $json->decode(join("", <IN>)); 
        close(IN);
    }
    return $data;
}

sub get_userattr {
    if (-s $global_attr) {
        return read_json($global_attr);
    } else {
        return {};
    }
}

sub create_attr {
    my ($name, $stats, $other) = @_;
    if (-s $global_attr) {
        my $attr = read_json($global_attr);
        if ($stats && ref($stats) && (scalar(keys %$stats) > 0)) {
            $attr->{statistics} = $stats;
        }
        if ($other && ref($other)&& (scalar(keys %$other) > 0)) {
            foreach my $key (keys %$other) {
                $attr->{$key} = $other->{$key};
            }
        }
        print_json($name, $attr);
    } else {
        logger('error', "missing $global_attr");
    }
}

######### Compute Stats ##########

sub get_seq_stats {
    my ($file, $type, $fast, $bins) = @_;
    unless ($file && (-s $file)) {
        return {};
    }
    my $cmd = "seq_length_stats.py -i $file";
    if ($type) {
        $cmd .= " -t $type";
    }
    if ($fast) {
        $cmd .= " -f"
    }
    if ($bins) {
        $cmd .= " -l $bins.lens -g $bins.gcs"
    }
    my @out = `$cmd`;
    chomp @out;
    my $stats = {};
    foreach my $line (@out) {
        if ($line =~ /^\[error\]/) {
            logger('error', $line);
            exit 1;
        }
        my ($k, $v) = split(/\t/, $line);
        $stats->{$k} = $v;
    }
    return $stats;
}

sub get_cluster_stats {
    my ($file) = @_;
    
    my $stats = {
        cluster_count => 0,
        clustered_sequence_count => 0
    };
    unless ($file && (-s $file)) {
        return $stats;
    }
    open(FILE, "<$file") || return $stats;
    while (my $line = <FILE>) {
        chomp $line;
        my @tabs = split(/\t/, $line);
        my @ids  = split(/,/, $tabs[2]);
        $stats->{cluster_count} += 1;
        $stats->{clustered_sequence_count} += scalar(@ids) + 1;
    }
    close(FILE);
    return $stats;
}

# enable hash-resolving in the JSON->encode function
sub TO_JSON { return { %{ shift() } }; }

1;
