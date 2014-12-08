#!/usr/bin/env perl

# MG-RAST pipeline job submitter for AWE
# Command name: submit_to_awe
# Use case: submit a job with a local input file and a pipeline template,
#           input file is local and will be uploaded to shock automatially.
# Operations:
#      1. upload input file to shock OR copy input shock node
#      2. create job script based on job template and available info
#      3. submit the job json script to awe

use strict;
use warnings;
no warnings('once');

use PipelineJob;
use PipelineAWE_Conf;

use JSON;
use Template;
use Getopt::Long;
use LWP::UserAgent;
use HTTP::Request::Common;
use Data::Dumper;


use AWE::Workflow; # includes Shock::Client
use AWE::Client;


use File::Slurp;

# options
my $job_id     = "";
my $input_file = "";
my $input_node = "";
my $awe_url    = "";
my $shock_url  = "";
my $template   = "";
my $clientgroups = undef;
my $no_start   = 0;
my $use_ssh    = 0;
my $use_docker = 0;
my $help       = 0;
my $pipeline   = "mgrast-test"; # will be overwritten by --production
my $type       = "metagenome-test"; # will be overwritten by --production
my $production = 0; # indicates that this is production

my $options = GetOptions (
        "job_id=s"     => \$job_id,
        "input_file=s" => \$input_file,
        "input_node=s" => \$input_node,
		"awe_url=s"    => \$awe_url,
		"shock_url=s"  => \$shock_url,
		"template=s"   => \$template,
		"no_start!"    => \$no_start,
		"use_ssh!"     => \$use_ssh,
		"use_docker!"  => \$use_docker, # enables docker specific workflow entries, dockerimage and environ
		"clientgroups=s" => \$clientgroups,
		"pipeline=s"      => \$pipeline,
		"type=s"       => \$type,
		"production!"     => \$production,
		"help!"        => \$help
);

if ($help) {
    print get_usage();
    exit 0;
} elsif (! $job_id) {
    print STDERR "ERROR: A job identifier is required.\n";
    exit 1;
} elsif (! ($input_file || $input_node)) {
    print STDERR "ERROR: An input file or node was not specified.\n";
    exit 1;
} elsif ($input_file && (! -e $input_file)) {
    print STDERR "ERROR: The input file [$input_file] does not exist.\n";
    exit 1;
}


#########################################################


sub submit_workflow {
	my ($workflow, $aweserverurl, $shocktoken, $awetoken) = @_;
	my $debug = 0;
	############################################
	# connect to AWE server and check the clients
	my $awe = new AWE::Client($aweserverurl, $shocktoken, $awetoken, $debug); # second token is for AWE
	unless (defined $awe) {
		die;
	}
	#$awe->checkClientGroup($self->clientgroup)==0 || die "no clients in clientgroup found, ".$self->clientgroup." (AWE server: ".$self->aweserverurl.")";
	print "submit job to AWE server...\n";
	my $json = JSON->new;
	my $submission_result = $awe->submit_job('json_data' => $json->encode($workflow->getHash()));
	unless (defined $submission_result) {
		die "error: submission_result is not defined";
	}
	unless (defined $submission_result->{'data'}) {
		print STDERR Dumper($submission_result);
		exit(1);
	}
	my $job_id = $submission_result->{'data'}->{'id'} || die "no job_id found";
	print "result from AWE server:\n".$json->pretty->encode( $submission_result )."\n";
	return $job_id;
}


#########################################################

if ($production) {
	
	$pipeline = "mgrast-prod"; # production default
	
	$type = "metagenome"; # production default
	
}

# set obj handles
my $jobdb=undef;

if ($use_ssh) {
    my $mspath = $ENV{'HOME'}.'/.mysql/';
	$jobdb = PipelineJob::get_jobcache_dbh(
    	$PipelineAWE_Conf::job_dbhost,
		$PipelineAWE_Conf::job_dbname,
    	$PipelineAWE_Conf::job_dbuser,
    	$PipelineAWE_Conf::job_dbpass,
		$mspath.'client-key.pem',
		$mspath.'client-cert.pem',
		$mspath.'ca-cert.pem'
	);
} else {
    $jobdb = PipelineJob::get_jobcache_dbh(
		$PipelineAWE_Conf::job_dbhost,
		$PipelineAWE_Conf::job_dbname,
		$PipelineAWE_Conf::job_dbuser,
		$PipelineAWE_Conf::job_dbpass
	);
}

my $tpage = Template->new(ABSOLUTE => 1);
my $agent = LWP::UserAgent->new();
$agent->timeout(3600);
my $json = JSON->new;
$json = $json->utf8();
$json->max_size(0);
$json->allow_nonref;

# get default urls
my $vars = $PipelineAWE_Conf::template_keywords;
if ($shock_url) {
    $vars->{shock_url} = $shock_url;
}
if (! $awe_url) {
    $awe_url = $PipelineAWE_Conf::awe_url;
}
if (! $template) {
    $template = $PipelineAWE_Conf::template_file;
}


#my $template_str = read_file($template) ;


# get job related info from DB
my $jobj = PipelineJob::get_jobcache_info($jobdb, $job_id);
unless ($jobj && (scalar(keys %$jobj) > 0) && exists($jobj->{options})) {
    print STDERR "ERROR: Job $job_id does not exist.\n";
    exit 1;
}
my $jstat = PipelineJob::get_job_statistics($jobdb, $job_id);
my $jattr = PipelineJob::get_job_attributes($jobdb, $job_id);
my $jopts = {};
foreach my $opt (split(/\&/, $jobj->{options})) {
    if ($opt =~ /^filter_options=(.*)/) {
        $jopts->{filter_options} = $1 || 'skip';
    } else {
        my ($k, $v) = split(/=/, $opt);
        $jopts->{$k} = $v;
    }
}

# build upload attributes
my $up_attr = {
    id          => 'mgm'.$jobj->{metagenome_id},
    job_id      => $job_id,
    name        => $jobj->{name},
    created     => $jobj->{created_on},
    status      => 'private',
    assembled   => $jattr->{assembled} ? 'yes' : 'no',
    data_type   => 'sequence',
    seq_format  => 'bp',
    file_format => ($jattr->{file_type} && ($jattr->{file_type} eq 'fastq')) ? 'fastq' : 'fasta',
    stage_id    => '050',
    stage_name  => 'upload',
    type        => $type,
    statistics  => {},
    sequence_type    => $jobj->{sequence_type} || $jattr->{sequence_type_guess},
    pipeline_version => $vars->{pipeline_version}
};
if ($jobj->{project_id} && $jobj->{project_name}) {
    $up_attr->{project_id}   = 'mgp'.$jobj->{project_id};
    $up_attr->{project_name} = $jobj->{project_name};
}
foreach my $s (keys %$jstat) {
    if ($s =~ /(.+)_raw$/) {
        $up_attr->{statistics}{$1} = $jstat->{$s};
    }
}

my $content = {};
$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;

if ($input_file) {
    # upload input to shock
    $content = {
        upload     => [$input_file],
        attributes => [undef, "$input_file.json", Content => $json->encode($up_attr)]
    };
} elsif ($input_node) {
    # copy input node
    $content = {
        copy_data => $input_node,
        attributes => [undef, "attr.json", Content => $json->encode($up_attr)]
    };
}
# POST to shock
print "upload input to Shock... ";
my $spost = $agent->post(
    $vars->{shock_url}.'/node',
    'Authorization', 'OAuth '.$PipelineAWE_Conf::shock_pipeline_token,
    'Content_Type', 'multipart/form-data',
    'Content', $content
);
my $sres = undef;
eval {
    $sres = $json->decode($spost->content);
};
if ($@) {
    print STDERR "ERROR: Return from shock is not JSON:\n".$spost->content."\n";
    exit 1;
}
if ($sres->{error}) {
    print STDERR "ERROR: (shock) ".$sres->{error}[0]."\n";
    exit 1;
}
print " ...done.\n";

my $node_id = $sres->{data}->{id};
my $file_name = $sres->{data}->{file}->{name};
print "upload shock node\t$node_id\n";

# populate workflow variables
$vars->{job_id}         = $job_id;
$vars->{mg_id}          = $up_attr->{id};
#$vars->{mg_name}        = $up_attr->{name};
$vars->{job_date}       = $up_attr->{created};
$vars->{file_format}    = $up_attr->{file_format};
$vars->{seq_type}       = $up_attr->{sequence_type};
$vars->{bp_count}       = $up_attr->{statistics}{bp_count};
$vars->{project_id}     = $up_attr->{project_id} || '';
#$vars->{project_name}   = $up_attr->{project_name} || '';
#$vars->{user}           = 'mgu'.$jobj->{owner} || '';
$vars->{inputfile}      = $file_name;
$vars->{shock_node}     = $node_id;
$vars->{filter_options} = $jopts->{filter_options} || 'skip';
$vars->{assembled}      = exists($jattr->{assembled}) ? $jattr->{assembled} : 0;
$vars->{dereplicate}    = exists($jopts->{dereplicate}) ? $jopts->{dereplicate} : 1;
$vars->{bowtie}         = exists($jopts->{bowtie}) ? $jopts->{bowtie} : 1;
$vars->{screen_indexes} = exists($jopts->{screen_indexes}) ? $jopts->{screen_indexes} : 'h_sapiens';


 
if (defined $pipeline && $pipeline ne "") {
	$vars->{'pipeline'} = $pipeline;
} else {
	die "template variable \"pipeline\" not defined";
}

if (defined $type && $type ne "") {
	$vars->{'type'} = $type;
} else {
	die "template variable \"type\" not defined";
}


if (defined $clientgroups) {
	$vars->{'clientgroups'} = $clientgroups;
}


# set priority
my $priority_map = {
    "never"       => 1,
    "date"        => 5,
    "6months"     => 10,
    "3months"     => 15,
    "immediately" => 20
};
if ($jattr->{priority} && exists($priority_map->{$jattr->{priority}})) {
    $vars->{priority} = $priority_map->{$jattr->{priority}};
}
# higher priority if smaller data
if (int($up_attr->{statistics}{bp_count}) < 100000000) {
    $vars->{priority} = 30;
}
if (int($up_attr->{statistics}{bp_count}) < 50000000) {
    $vars->{priority} = 40;
}
if (int($up_attr->{statistics}{bp_count}) < 10000000) {
    $vars->{priority} = 50;
}



##############################################################################################################

my $workflow = new AWE::Workflow(
	"pipeline"		=> $pipeline,
	"name"			=> $job_id,
	"project"		=> $up_attr->{project_name} || '',
	"user"			=> 'mgu'.$jobj->{owner} || '',
	"clientgroups"	=> $clientgroups,
	"priority" 		=> $vars->{priority},
	"shockhost" 	=> $vars->{shock_url} || die, # default shock server for output files
	"shocktoken" 	=> $PipelineAWE_Conf::shock_pipeline_token || die,
	"userattr" => {
		"id"				=> $vars->{'mg_id'},
		"job_id"			=> $job_id,
		"name"				=> $vars->{'mg_name'},
		"created"			=> $vars->{'job_date'},
		"status"			=> "private",
		"owner"				=> $vars->{'user'},
		"sequence_type"		=> $vars->{'seq_type'},
		"bp_count"			=> $vars->{'bp_count'},
		"project_id"		=> $vars->{'project_id'},
		"project_name"		=> $vars->{'project_name'},
		"type"				=> $vars->{'type'},
		"pipeline_version"	=> $vars->{'pipeline_version'}
	}
);



### qc ###
#https://github.com/MG-RAST/Skyport/blob/master/app_definitions/MG-RAST/qc.json

#my $task_qc = $workflow->newTask(	'MG-RAST/qc.qc.default',
#									shock_resource($vars->{shock_url}, $node_id, $file_name),
#									string_resource($up_attr->{file_format}),
#									string_resource($job_id),
#									string_resource($vars->{assembled}),
#									string_resource($vars->{filter_options})
#);

#$task_qc->userattr(	"stage_id" 		=> "075",
#					"stage_name" 	=> "qc"
#);




### preprocess (optional, fastq or fasta) ###
#https://github.com/MG-RAST/Skyport/blob/master/app_definitions/MG-RAST/base.json

my $task_preprocess = undef;
if ($vars->{filter_options} ne 'skip') {
	print "preprocess\n";
	
	$task_preprocess = $workflow->newTask(	'MG-RAST/base.preprocess.'.$up_attr->{file_format},
		shock_resource($vars->{shock_url}, $node_id, $file_name),
		string_resource($job_id),
		string_resource($vars->{filter_options})
	);
		
	
	
	$task_preprocess->userattr(
		"stage_id"		=> "100",
		"stage_name"	=> "preprocess",
		"file_format"	=> "fasta",
		"seq_format"	=> "bp"
	);
	
}



### dereplicate ###
my $task_dereplicate = undef;
if ($vars->{dereplicate} != 0) {
	print "dereplicate\n";
	
	my $dereplicate_input = undef;
	if (defined $task_preprocess) {
		$dereplicate_input = task_resource($task_preprocess->taskid(), 'passed')
	} else {
		$dereplicate_input = shock_resource($vars->{shock_url}, $node_id, $file_name);
	}
	$task_dereplicate = $workflow->newTask(	'MG-RAST/base.dereplicate.default',
		$dereplicate_input,
		string_resource($job_id),
		string_resource($vars->{prefix_length}),
		string_resource($vars->{dereplicate})
	);
	
	$task_dereplicate->userattr(
		"stage_id"		=> "150",
		"stage_name"	=> "dereplication",
		"file_format"	=> "fasta",
		"seq_format"	=> "bp"
	);
}


### bowtie_screen ###
my $bowtie_screen_input = undef; # since previous two tasks are optional, figure out the input for this task.

if ($vars->{bowtie} != 0 ) {
	print "bowtie ".$vars->{screen_indexes}."\n";
	
	my @bowtie_index_files=();
	
	# check if index exists
	my $has_index = 0;
	foreach my $idx (split(/,/, $vars->{screen_indexes})) {
		if (exists $PipelineAWE_Conf::shock_bowtie_indexes->{$idx}) {
			$has_index = 1;
		}
	}
	if (! $has_index) {
		# just use default
		$vars->{screen_indexes} = 'h_sapiens';
	}
	# build bowtie index list
	my $bowtie_url = $PipelineAWE_Conf::shock_bowtie_url || $vars->{shock_url};
	$vars->{index_download_urls} = "";
	foreach my $idx (split(/,/, $vars->{screen_indexes})) {
		if (exists $PipelineAWE_Conf::shock_bowtie_indexes->{$idx}) {
			while (my ($ifile, $inode) = each %{$PipelineAWE_Conf::shock_bowtie_indexes->{$idx}}) {
				print "bowtie ".$ifile."\n";
				my $sr = shock_resource( ${bowtie_url} , ${inode}, $ifile );
				$sr->{'cache'} = JSON::true; # this inidicates predata files
				push(@bowtie_index_files, $sr );
			}
		}
	}
	if (@bowtie_index_files == 0 ) {
		die "@bowtie_index_files empty";
	}
	
	
	
	
	
	
	if (defined $task_dereplicate) {
		$bowtie_screen_input = task_resource($task_dereplicate->taskid(), 'passed');
	} else {
		if (defined $task_preprocess) {
			$bowtie_screen_input = task_resource($task_preprocess->taskid(), 'passed');
		} else {
			$bowtie_screen_input = shock_resource($vars->{shock_url}, $node_id, $file_name);
		}
	}

	my $task_bowtie_screen = $workflow->newTask('MG-RAST/bowtie.bowtie.default',
		$bowtie_screen_input,
		string_resource($job_id),
		string_resource($vars->{screen_indexes}),
		string_resource($vars->{bowtie}),
		list_resource(\@bowtie_index_files)
	);

	$task_bowtie_screen->userattr(
		"stage_id"		=> "299",
		"stage_name"	=> "screen",
		"data_type"		=> "sequence",
		"file_format"	=> "fasta",
		"seq_format"	=> "bp"
	);



}




### diamond ###
my $task_diamond = $workflow->newTask('diamond.search.blastx',
	task_resource($task_bowtie_screen->taskid(), 'passed'),
	shock_resource($vars->{shock_url}, $XXXXXnode_id, $XXXXXfile_name), # diamond database for M5NR
	string_resource($job_id)
);



$task_diamond->userattr(
	"stage_id"		=> "???",
	"stage_name"	=> "diamond",
	"m5nr_sims_version" => "???",
	"data_type"		=> "similarity",
	"file_format"	=> "blast m8",
	"sim_type"		=> "protein"
);


my $diamon_result = task_resource($task_diamond->taskid(), 'result');



my $workflow_str = $json->pretty->encode( $workflow->getHash() );
print "AWE workflow:\n".$workflow_str."\n";



#write to file for debugging puposes (first time)
my $workflow_file = $PipelineAWE_Conf::temp_dir."/".$job_id.".awe_workflow.json";
write_file($workflow_file, $workflow_str);

# transform workflow json string into hash
my $workflow_hash = undef;
eval {
	$workflow_hash = $json->decode($workflow_str);
};
if ($@) {
	my $e = $@;
	print "workflow_str:\n $workflow_str\n";
	print STDERR "ERROR: workflow is not valid json ($e)\n";
	exit 1;
}



# test mode
if ($no_start) {
    print "workflow\t".$workflow_file."\n";
    exit 0;
}


print "\nsubmiting .....\n";

my $awe_id = submit_workflow($workflow, $awe_url, $PipelineAWE_Conf::shock_pipeline_token, $PipelineAWE_Conf::awe_pipeline_token);

exit(0);




# get info
my $awe_id  = $ares->{data}{id};
my $awe_job = "job_TODO";
print "awe job (".$ares->{data}{jid}.")\t".$ares->{data}{id}."\n";

sub get_usage {
    return "USAGE: submit_to_awe.pl -job_id=<job identifier> -input_file=<input file> -input_node=<input shock node> [-awe_url=<awe url> -shock_url=<shock url> -template=<template file> -no_start]\n";
}

# enable hash-resolving in the JSON->encode function
sub TO_JSON { return { %{ shift() } }; }

