package PipelineAWE;

use strict;
use warnings;
no warnings('once');

use PipelineAWE_Conf;

use JSON;
use Data::Dumper;

my $global_attr = "userattr.json";
my $json = JSON->new;
$json = $json->utf8();
$json->max_size(0);
$json->allow_nonref;

sub run_cmd {
    my ($cmd, $shell) = @_;
    
    my $status = undef;
    my @parts  = split(/ /, $cmd);
    print STDOUT $cmd."\n";
    
    if ($shell) {
        $status = system($cmd);
    } else {
        $status = system(@parts);
    }
    
    if ($status != 0) {
        print STDERR "ERROR: ".$parts[0]." returns value $status\n";
        exit $status;
    }
}

sub print_json {
    my ($file, $data) = @_;
    open(OUT, ">$file") or die "Couldn't open file: $!";
    print OUT $json->encode($data);
    close(OUT);
}

sub create_attr {
    my ($name, $stats, $other) = @_;
    
    if (-s $global_attr) {
        open(IN, "<$global_attr") or die "Couldn't open file: $!";
        my $all_attr = $json->decode(join("", <IN>)); 
        close(IN);
        
        my %attr = (%{$all_attr->{jobattr}}, %{$all_attr->{taskattr}});
        if ($stats && ref($stats) && (scalar(keys %$stats) > 0)) {
            $attr{statistics} = $stats;
        }
        if ($other && ref($other)&& (scalar(keys %$other) > 0)) {
            foreach my $key (keys %$other) {
                $attr{$key} = $other->{$key};
            }
        }
        print_json($name, \%attr);
    } else {
        print STDERR "missing $global_attr\n";
    }
}

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
            print STDERR $line."\n";
            exit 1;
        }
        my ($k, $v) = split(/\t/, $line);
        $stats->{$k} = $v;
    }
    return $stats;
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

sub get_jobcache_dbh {
  my $dbh;
  $dbh = DBI->connect("DBI:mysql:database=".$PipelineAWE_Conf::job_dbname.";host=".$PipelineAWE_Conf::job_dbhost, 
		      $PipelineAWE_Conf::job_dbuser, "") or die $DBI::errstr;
  return $dbh;
}

sub get_jobcache_info { 
  my $job = shift;
  my $dbh = get_jobcache_dbh();
  my $query = $dbh->prepare(qq(select * from Job where job_id=?));
  $query->execute($job);
  my $data = $query->fetchrow_hashref;
  if ($data->{primary_project}) {
      my $pquery = $dbh->prepare(qq(select * from Project where _id=?));
      $pquery->execute($data->{primary_project});
      my $pdata = $pquery->fetchrow_hashref;
      if ($pdata->{name} && $pdata->{id}) {
          $data->{project_name} = $pdata->{name};
          $data->{project_id} = $pdata->{id};
      }
  }
  return $data;
}

sub get_job_attributes {
  my ($job, $tags) = @_;
  return get_job_tag_data($job, $tags, "JobAttributes");
}

sub get_job_statistics {
  my ($job, $tags) = @_;
  return get_job_tag_data($job, $tags, "JobStatistics");
}

sub get_job_tag_data {
  my ($job, $tags, $table) = @_;

  my $data    = {};
  my $job_obj = get_jobcache_info($job);
  my $dbh     = get_jobcache_dbh();

  unless ($job_obj && $job_obj->{_id}) {
    return $data;
  }
  my $query = "select tag, value from $table where job=" . $job_obj->{_id} . " and _job_db=2";
  if ($tags && (@$tags > 0)) {
    $query .= " and tag in (" . join(",", map {$dbh->quote($_)} @$tags) . ")";
  }
  my $rows = $dbh->selectall_arrayref($query);
  if ($rows && (@$rows > 0)) {
    %$data = map { $_->[0], $_->[1] } @$rows;
  }
  return $data;
}

# enable hash-resolving in the JSON->encode function
sub TO_JSON { return { %{ shift() } }; }

1;
