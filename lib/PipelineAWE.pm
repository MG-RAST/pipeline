package PipelineAWE;

use strict;
use warnings;
no warnings('once');

use JSON;
use Data::Dumper;
use LWP::UserAgent;
use Net::SMTP;

our $debug = 1;
our $layout = '[%d] [%-5p] %m%n';
our $default_api = "http://api.metagenomics.anl.gov";
our $mg_email = '"Metagenomics Analysis Server" <mg-rast@mcs.anl.gov>';
our $mg_smtp = 'smtp.mcs.anl.gov';
our $global_attr = "userattr.json";
our $agent = LWP::UserAgent->new();
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
    my @parts  = split(/ /, $cmd);
    logger('info', $cmd);
    eval {
        if ($shell) {
            $status = system($cmd);
        } else {
            $status = system(@parts);
        }
    };
    if ($@) {
        logger('error', "died running child process ".$parts[0]);
        logger('debug', $parts[0]." throws: ".$@);
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
    my ($url, $key, $data) = @_;
    my $content = undef;
    my $result  = undef;
    my @args    = $key ? ('Auth', $key) : ();
    if ($data && ref($data)) {
        push @args, ('Content-Type', 'application/json');
        $result = $agent->post($url, @args, 'Content' => $json->encode($data));
    } else {
        $result = $agent->get($url, @args);
    }
    if (! ref($result)) {
        logger('error', "unable to connect to $url");
        exit 1;
    }
    eval {
        $content = $json->decode( $result->content );
    };
    if ($@ || (! ref($content))) {
        logger('error', $result->content);
        exit 1;
    } elsif ($content->{'ERROR'}) {
        logger('error', "from $url: ".$content->{'ERROR'});
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
        my $smtp = Net::SMTP->new($mg_smtp);
        my $reciever = "\"$owner_name\" <".$user_info->{email}.">"
        $smtp->mail('mg-rast');
        if ($smtp->to($receiver)) {
            $smtp->data($body);
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
