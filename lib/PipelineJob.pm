package PipelineJob;

use strict;
use warnings;
no warnings('once');

use DBI;
use Data::Dumper;

sub get_jobcache_dbh {
    my ($dbhost, $dbname, $dbuser, $dbpass) = @_;
    my $dbh = DBI->connect("DBI:mysql:database=".$dbname.";host=".$dbhost, $dbuser, $dbpass) || die $DBI::errstr;
    return $dbh;
}

sub get_jobcache_info {
    my ($dbh, $job) = @_;
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
    my ($dbh, $jobid) = @_;
    return get_job_tag_data($dbh, $jobid, "JobAttributes");
}

sub get_job_statistics {
    my ($dbh, $jobid) = @_;
    return get_job_tag_data($dbh, $jobid, "JobStatistics");
}

sub get_job_tag_data {
    my ($dbh, $jobid, $table) = @_;
    my $data  = {};
    my $query = "select tag, value from $table where job=(select _id from Job where job=$jobid) and _job_db=2";
    my $rows  = $dbh->selectall_arrayref($query);
    if ($rows && (@$rows > 0)) {
        %$data = map { $_->[0], $_->[1] } @$rows;
    }
    return $data;
}

sub set_job_attributes {
    my ($dbh, $jobid, $data) = @_;
    return set_job_tag_data($dbh, $jobid, $data, "JobAttributes");
}

sub set_job_statistics {
    my ($dbh, $jobid, $data) = @_;
    return set_job_tag_data($dbh, $jobid, $data, "JobStatistics");
}

sub set_job_tag_data {
    my ($dbh, $jobid, $data, $table) = @_;
    unless ($data && %$data) {
        return 0;
    }
    my $query = $dbh->prepare(qq(insert into $table (`tag`,`value`,`job`,`_job_db`) values (?,?,(select _id from Job where job=$jobid),2) on duplicate key update value=?));
    while ( my ($tag, $val) = each(%$data) ) {
        $query->execute($tag, $val, $val) || return 0;
    }
    return 1
}

1;
