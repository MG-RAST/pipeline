#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use Getopt::Long;

my $verbose = 0;
my $reload  = 0;
my $table   = "";
my $dbname  = "";
my $dbhost  = "";
my $dbuser  = "";
my $usage   = qq($0
load precomputed job data into database.

  --table      table name     Name of search table
  --dbhost     db user        Server of database
  --dbname     db name        Name of database
  --dbuser     db user        Owner of database
  --reload                    Optional. Reload table from scratch.
  --verbose                   Optional. Verbose output.
);
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { print STDERR $usage; exit 1; }
if ( ! &GetOptions ('verbose!' => \$verbose,
		    'reload!'  => \$reload,
		    'table:s'  => \$table,
		    'dbhost:s' => \$dbhost,
		    'dbname:s' => \$dbname,
		    'dbuser:s' => \$dbuser,
		   ) )
  { print STDERR $usage; exit 1; }

my $dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost", $dbuser, '', {AutoCommit => 0 , RaiseError => 1});
unless ($dbh) { print STDERR "Error: " . $DBI::errstr . "\n"; exit 1; }

my $data  = {};
my $count = 0;
my $added = {};
my $sql   = "SELECT DISTINCT job_id,table_name,table_type FROM job_tables WHERE table_type IN ('organism','function','ontology') AND loaded='true'" . ($reload ? "" : " AND indexed='false'");
my $tbls  = $dbh->selectall_arrayref($sql);
$dbh->commit;

# get data from tables
if ($verbose) { print STDERR "Retrieving data from Jobs Tables for " . scalar(@$tbls) . " tables (per 100) "; }
foreach my $entry (@$tbls) {
  my ($job, $tbl, $type) = @$entry;
  $count += 1;
  if ($verbose && (($count % 100) == 0)) { print STDERR "."; }

  if ($type eq 'organism') {
    my $all_orgs = $dbh->selectall_arrayref(qq(SELECT DISTINCT organism, source FROM $tbl));
    map { $data->{organism}{$_->[0]}{$_->[1]}{$job} = 1 } grep { $_->[0] && $_->[1] } @$all_orgs;
  }
  elsif ($type eq 'function') {
    my $all_funcs = $dbh->selectall_arrayref(qq(SELECT DISTINCT function, source FROM $tbl));
    map { $data->{function}{$_->[0]}{$_->[1]}{$job} = 1 } grep { $_->[0] && $_->[1] } @$all_funcs;
  }
  elsif ($type eq 'ontology') {
    my $all_onts = $dbh->selectall_arrayref(qq(SELECT DISTINCT id, annotation, source FROM $tbl));
    map { $data->{ontology}{$_->[0] . " : " . $_->[1]}{$_->[2]}{$job} = 1 } grep { $_->[0] && $_->[1] && $_->[2] } @$all_onts;
  }
  $dbh->commit;
}
if ($verbose) { print STDERR " Done.\n"; }

# create table
if ($reload) {
  if ($verbose) { print STDERR "Creating $table table ... "; }
  $dbh->do("DROP TABLE IF EXISTS $table");
  $dbh->do("CREATE TABLE $table (name text NOT NULL, abundance integer NOT NULL, type text, source text, jobs integer[])");
  $dbh->commit;
  if ($verbose) { print STDERR "Done.\n"; }
}

# parse data and load
if ($verbose) { print STDERR "Loading data (per 10000) "; }
my $select = $dbh->prepare("SELECT COUNT(*) FROM $table WHERE name=? AND type=? AND source=?");
my $insert = $dbh->prepare("INSERT INTO $table (name, abundance, type, source, jobs) VALUES (?,?,?,?,?)");
my (%m5nr, @jobs, $res);

$count = 0;
foreach my $type (keys %$data) {
  foreach my $name (keys %{$data->{$type}}) {
    %m5nr = ();
    $count += 1;
    if ($verbose && (($count % 10000) == 0)) { print STDERR "."; }
    foreach my $src (keys %{$data->{$type}{$name}}) {
      $res  = 0;
      @jobs = keys %{$data->{$type}{$name}{$src}};
      map { $m5nr{$_} = 1 } @jobs;

      if ($reload) {
	$res = $insert->execute($name, scalar(@jobs), $type, $src, "{" . join(",", @jobs) . "}");
      }
      else {
	$select->execute($name, $type, $src);
	my $num = $select->fetchrow_arrayref();
	if ($num && (@$num == 1) && ($num->[0] > 0)) {
	  $res = $dbh->do("UPDATE $table SET abundance = abundance + ".scalar(@jobs).", jobs = jobs || ARRAY[".join(",", @jobs)."] WHERE name=".$dbh->quote($name)." AND type='$type' AND source='$src'");
	} else {
	  $res = $insert->execute($name, scalar(@jobs), $type, $src, "{" . join(",", @jobs) . "}");
	}
      }
      unless ($res && ($res == 1)) {
	print STDERR "ERROR:\t" . $dbh->errstr . " : $res\n"; exit 1;
      }
      map { $added->{$type}->{$_} = 1 } @jobs;
    }
    $res  = 0;
    @jobs = keys %m5nr;

    if ($reload) {
      $res = $insert->execute($name, scalar(@jobs), $type, "M5NR", "{" . join(",", @jobs) . "}");
    }
    else {
      $select->execute($name, $type, "M5NR");
      my $num = $select->fetchrow_arrayref();
      if ($num && (@$num == 1) && ($num->[0] > 0)) {
	$res = $dbh->do("UPDATE $table SET abundance = abundance + ".scalar(@jobs).", jobs = jobs || ARRAY[".join(",", @jobs)."] WHERE name=".$dbh->quote($name)." AND type='$type' AND source='M5NR'");
      } else {
	$res = $insert->execute($name, scalar(@jobs), $type, "M5NR", "{" . join(",", @jobs) . "}");
      }
    }
    unless ($res && ($res == 1)) {
      print STDERR "ERROR:\t" . $dbh->errstr . " : $res\n"; exit 1;
    }
    map { $added->{$type}{$_} = 1 } @jobs;
  }
}
$dbh->commit;
$select->finish;
$insert->finish;
if ($verbose) { print STDERR " Done.\n"; }

# create indexes
if ($reload) {
  if ($verbose) { print STDERR "Indexing $table table ... "; }
  $dbh->do("CREATE INDEX ${table}_key ON $table (name, type, source)");
  $dbh->commit;
  if ($verbose) { print STDERR "Done.\n"; }
}

# update jobs table
if ($verbose) { print STDERR "Updating job_tables with indexed jobs ... "; }
my $update_idx = $dbh->prepare("UPDATE job_tables SET indexed = 'true' WHERE job_id=? AND table_type=?");
my $all_jobs   = {};
foreach my $type (keys %$added) {
  foreach my $job (keys %{$added->{$type}}) {
    $update_idx->execute($job, $type);
    $all_jobs->{$job} = 1;
  }
}
$dbh->commit;
if ($verbose) { print STDERR "Done.\n"; }

$dbh->disconnect;
if ($verbose) { print STDERR scalar(keys %$all_jobs) . " jobs added to search table\n"; }
exit 0;
