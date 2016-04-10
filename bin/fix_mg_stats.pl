#!/usr/bin/env perl

use strict;
use warnings;
no warnings('once');

use Getopt::Long;

my $mg_id   = "";
my $api_url = "http://api.metagenomics.anl.gov";
my $api_key = "";

GetOptions(
    "mgid=s" => \$mg_id,
    "api=s"  => \$api_url,
    "key=s"  => \$api_key
);

unless ($mg_id && $api_key) {
    print STDERR "ERROR: --mgid and --key are required.\n";
    exit 1;
}

# current stats
my $mg_data = obj_from_url($api_url."/metagenome/".$mg_id."?verbosity=stats", $api_key);
my $mgstats = $mg_data->{statistics};
my $seq_num = $mgstats->{sequence_stats}{sequence_count_raw};

# stats node
my $stat_node = "";
my $stat_down = obj_from_url($api_url."/download/".$mg_id."?stage=999");
foreach my $n (@{$stat_down->{data}}) {
    if ($n->{data_type} eq "statistics") {
        $stat_node = $n->{node_id};
    }
}
unless ($stat_node) {
    print STDERR "ERROR: no existing stats node\n";
    exit 1;
}

my t1 = time;
# get abundance stats from API, this is an asynchronous call
my $get_abund = obj_from_url($api_url."/job/abundance/".$mg_id."?type=all&ann_ver=1", $api_key);
while ($get_abund->{status} != 'done') {
    sleep 30;
    $get_abund = obj_from_url($get_abund->{url});
}
my $abundances = $get_abund->{data};
print STDERR "compute abundace time: ".(time - t1)."\n"
print STDERR "taxa: ".scalar(@{$abundances->{taxonomy}})."\n";
print STDERR "func: ".scalar(@{$abundances->{function}})."\n";
print STDERR "ontol: ".scalar(@{$abundances->{ontology}})."\n";

t2 = time
# diversity computation from API, this is an asynchronous call
my $get_diversity = obj_from_url($api_url."/compute/rarefaction/".$mg_id."?asynchronous=1&alpha=1&level=species&ann_ver=1&seq_num=".$seq_num, $api_key);
while ($get_diversity->{status} != 'done') {
    sleep 30;
    $get_diversity = obj_from_url($get_diversity->{url});
}
my $alpha_rare = $get_diversity->{data};
print STDERR "compute alpha_rare time: ".(time - t2)."\n"
print STDERR "alpha: ".$alpha_rare->{alphadiversity}."\n";
print STDERR "rare: ".scalar(@{$alpha_rare->{rarefaction}})."\n";

exit 0;

# new stats
$mgstats->{taxonomy} = $abundances->{taxonomy};
$mgstats->{function} = $abundances->{function};
$mgstats->{ontology} = $abundances->{ontology};
$mgstats->{rarefaction} = $alpha_rare->{rarefaction};
$mgstats->{sequence_stats}{alpha_diversity_shannon} = $alpha_rare->{alphadiversity};

# new stats node
my $stat_obj = obj_from_url("http://shock.metagenomics.anl.gov/node/".$stat_node, $api_key);
my $attr = $stat_obj->{data}{attributes};
#set_shock_node("http://shock.metagenomics.anl.gov/node", "statistics.json", $mgstats, $attr, $api_key);

# upload of solr data
my $solrdata = {
    sequence_stats => $mgstats->{sequence_stats},
    function => [ map {$_->[0]} @{$mgstats->{function}} ],
    organism => [ map {$_->[0]} @{$mgstats->{taxonomy}{species}} ]
};
#obj_from_url($api_url."/job/solr", $api_key, {metagenome_id => $mg_id, solr_data => $solrdata});

# create node with optional file and/or attributes
# file is json struct by default
sub set_shock_node {
    my ($url, $name, $file, $attr, $auth) = @_;
    
    my $response = undef;
    my $content = {};
    if ($file) {
        my $file_str = $self->json->encode($file);
        $content->{upload} = [undef, $name, Content => $file_str];
    }
    if ($attr) {
        $content->{attributes} = [undef, "$name.json", Content => $self->json->encode($attr)];
    }
    eval {
        my @args = (
            $auth ? ('authorization', "mgrast ".$auth) : (),
            'Content_Type', 'multipart/form-data',
            $content ? ('Content', $content) : ()
        );
        my $post = $self->agent->post($url, @args);
        $response = $self->json->decode( $post->content );
    };
    if ($@ || (! ref($response))) {
        return undef;
    } elsif (exists($response->{error}) && $response->{error}) {
        $self->return_data( {"ERROR" => "Unable to POST to Shock: ".$response->{error}[0]}, $response->{status} );
    } else {
        return $response->{data};
    }
}


sub obj_from_url {
    my ($url, $key, $data) = @_;
    my $content = undef;
    my $result  = undef;
    my @args    = $key ? ('authorization', "mgrast ".$key) : ();
    if ($data && ref($data)) {
        push @args, ('Content-Type', 'application/json');
        $result = $agent->post($url, @args, 'Content' => $json->encode($data));
    } else {
        $result = $agent->get($url, @args);
    }
    if (! ref($result)) {
        print STDERR "ERROR: Unable to connect to $url\n";
        exit 1;
    }
    eval {
        $content = $json->decode( $result->content );
    };
    if ($@ || (! ref($content))) {
        print STDERR "ERROR: ".$result->content."\n";
        exit 1;
    } elsif ($content->{'ERROR'} || $content->{'error'}) {
        print STDERR "From $url: ".($content->{'ERROR'} || $content->{'error'})."\n";
        exit 1;
    } else {
        return $content;
    }
}