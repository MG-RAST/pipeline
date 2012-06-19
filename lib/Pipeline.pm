package Pipeline;

use strict;
use warnings;
no warnings('once');

use Pipeline_Conf;
use Data::Dumper;
use DBI;
use List::Util qw(max min sum);

sub logger {
  use Log::Log4perl;
  use Log::Log4perl::Layout;
  use Log::Log4perl::Level;
  use Log::Dispatch::FileRotate;

  my $job = shift; 
  my $log = Log::Log4perl->get_logger();
  my $layout = Log::Log4perl::Layout::PatternLayout->new("[%d] %p - %F (%L) %m%n");
  
  if((defined $job) and ($job =~ /^\d+$/) and (-d get_job_dir($job)."/logs")){
    my $job_appender = Log::Log4perl::Appender->new("Log::Dispatch::File",
						 name      => "job_log",
						 filename  =>  get_job_dir($job)."/logs/pipeline.log");
    $job_appender->layout($layout);
    $log->add_appender($job_appender);
  } elsif ($job) {
    print STDERR "Error Pipeline::logger - Unable to create logger for job: $job\n";
    exit(1);
  }
  
  my $global_appender = Log::Log4perl::Appender->new("Log::Dispatch::FileRotate",
						     name      => 'global_log',
						     min_level => 'info',
						     filename  => $Pipeline_Conf::global_log_dir."/global_pipeline.log",
						     mode      => 'append' ,
						     size      => (1024*1024*1024*0.5), #500mb files
						     max       => 6,
						    ); 
  $global_appender->layout($layout);
  $log->add_appender($global_appender);

  my $screen_appender = Log::Log4perl::Appender->new("Log::Dispatch::Screen",
						     stderr    => 0,
						     utf8      => 1,
						    );
						     
  $screen_appender->layout($layout);
  $log->add_appender($screen_appender);

  $log->level($INFO);
  return $log;
}

sub info_file {
  use Config::IniFiles;
  use File::Touch;

  my $file = shift;
  my $info;
  unless(-e $file){
    $info = Config::IniFiles->new();
    $info->SetFileName($file);
  } else {
    $info = Config::IniFiles->new( -file => $file );
  }
  return $info;
}

sub get_job_dir {
  my $job = shift;
  my $dir    = $Pipeline_Conf::global_job_dir_new;
  my $suffix = get_job_suffix($job);
  return "$dir/$suffix/$job";
}

sub get_job_suffix {
  my $job = shift;
  my $len = length($job);
  if ($len == 1) {
    return "0$job";
  }
  else {
    return substr($job, -2, 2);
  }
}

sub get_jobcache_dbh {
  my $dbh;
  $dbh = DBI->connect("DBI:mysql:database=".$Pipeline_Conf::jobcache_db.";host=".$Pipeline_Conf::jobcache_host, 
		      $Pipeline_Conf::jobcache_user, 
		      $Pipeline_Conf::jobcache_password || "") or die $DBI::errstr;
  return $dbh;
}

sub get_ach_dbh {
  my $dbh;
  $dbh = DBI->connect("DBI:Pg:database=".$Pipeline_Conf::ach_db.";host=".$Pipeline_Conf::ach_host, 
		      $Pipeline_Conf::ach_user, 
		      $Pipeline_Conf::ach_password || "") or die $DBI::errstr;
  return $dbh;
}

sub get_analysis_dbh {
  my $dbh;
  $dbh = DBI->connect("DBI:Pg:database=".$Pipeline_Conf::analysis_db.";host=".$Pipeline_Conf::analysis_host, 
		      $Pipeline_Conf::analysis_user, 
		      $Pipeline_Conf::analysis_password || "") or die $DBI::errstr;
  return $dbh;
}

sub get_job_owner {
  my $job = shift;
  my $job_obj = get_jobcache_info($job);
  my $dbh = DBI->connect("DBI:mysql:database=".$Pipeline_Conf::webapp_db.";host=".$Pipeline_Conf::webapp_host, 
			 $Pipeline_Conf::webapp_user, 
			 $Pipeline_Conf::webapp_password || "") or die $DBI::errstr;
  my $query = $dbh->prepare(qq(select * from User where _id=?));
  $query->execute( $job_obj->{owner} );
  return $query->fetchrow_hashref;
}

sub get_job_options {
  my $job = shift;
  my $job_obj = get_jobcache_info($job);
  return $job_obj->{options} ? $job_obj->{options} : "";
}

sub get_jobcache_info { 
  my $job = shift;
  my $dbh = get_jobcache_dbh();
  my $query = $dbh->prepare(qq(select * from Job where job_id=?));
  $query->execute($job);
  return $query->fetchrow_hashref;
}

sub set_jobcache_info {
  my ($job, $col, $val) = @_;
  my $dbh = get_jobcache_dbh();
  my $query = $dbh->prepare(qq(update Job set $col=? where job_id=?));
  $query->execute($val, $job) or die $dbh->errstr;
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

sub set_job_attributes {
  my ($job, $data) = @_;
  return set_job_tag_data($job, $data, "JobAttributes");
}

sub set_job_statistics {
  my ($job, $data) = @_;
  return set_job_tag_data($job, $data, "JobStatistics");
}

sub set_job_tag_data {
  my ($job, $data, $table) = @_;

  my $job_obj = get_jobcache_info($job);
  my $dbh     = get_jobcache_dbh();
  my $query   = $dbh->prepare(qq(insert into $table (`tag`,`value`,`job`,`_job_db`) values (?,?,?,2) on duplicate key update value=?));

  unless ($data && @$data && $job_obj && $job_obj->{_id}) {
    return 0;
  }
  foreach my $set (@$data) {
    my ($tag, $val) = @$set;
    $query->execute($tag, $val, $job_obj->{_id}, $val) or die $dbh->errstr;
  }
  return 1;
}

sub update_stage_info { 
  my ($job, $stage, $status) = @_;
  my $dbh = get_jobcache_dbh();
  my $query = $dbh->prepare(qq(select * from Job where job_id=?));
  $query->execute($job) or die $dbh->errstr;  
  my $job_object = $query->fetchrow_hashref;  
  $query = $dbh->prepare(qq(insert into PipelineStage (`stage`,`status`,`job`,`_job_db`,`timestamp`) values (?,?,?,2,CURRENT_TIMESTAMP) on duplicate key update status=?));
  $query->execute($stage,$status,$job_object->{_id},$status) or die $dbh->errstr;
  return 1;
}

sub submit_stage {
  my ($stage) = @_;
  my ($script, $args, $qsub_options) = @{$stage};
  my $output = "";

  # test for script existance 
  $output = `which $script 2>&1`;

  if ($output =~ /^which:\s+no\s+$script\s+in\s+\((\S+)\)$/g) {
    return ["ERROR", "Could not find cmd: $script in env: ($1)"];
  } elsif ($output =~ /$script$/) {
	print "echo \"$script $args\" | qsub $qsub_options\n";
    my $torque_output = `echo "$script $args" | qsub $qsub_options`;
    if ($torque_output =~ /^(\d+)/){
      return ["SUCCESS", $1];
    } else {
      return ["ERROR", "Unexpected qsub output: $torque_output"];
    }
  } else {
    return ["ERROR", "Unexpected which output: $output"];
  }  
}

sub setspri {
  my ($tid, $num) = @_;

  system("sleep 1");
  my $output = `setspri +$num $tid`;
  if ($output =~ /job system priority adjusted/) {
    print "setspri +$num $tid\n";
    return "SUCCESS";
  } else {
    return "ERROR";
  }
}

sub get_taxa_abundances {
  my ($job, $taxa, $clump, $v) = @_;

  my $rows;
  my $data = {};
  my $ach_dbh  = get_ach_dbh();
  my $data_dbh = get_analysis_dbh();
  my $tax_md5  = {};
  my $tax_num  = [];

  $rows = $ach_dbh->selectall_arrayref("SELECT distinct name, tax_$taxa FROM organisms_ncbi");
  unless ($rows && (@$rows > 0)) { return []; }
  %$data = map { $_->[0], $_->[1] } grep { $_->[1] && ($_->[1] =~ /\S/) } @$rows;
  
  my $orgs = get_organism_md5s($job, $v);
  foreach my $o (keys %$orgs) {
    if (exists $data->{$o}) {
      map { $tax_md5->{$data->{$o}}->{$_} = 1 } @{ $orgs->{$o} };
    }
  }

  my $md5s  = get_md5_abundance($job, $v);
  my $other = 0;
  foreach my $d (sort keys %$tax_md5) {
    my $num = 0;
    map { $num += $md5s->{$_} } grep { exists $md5s->{$_} } keys %{ $tax_md5->{$d} };
    if ($clump && ($d =~ /other|unknown|unclassified/)) {
      $other += $num;
    } else {
      if ($num > 0) {
	push @$tax_num, [ $d, $num ];
      }
    }
  }
  if ($clump && ($other > 0)) {
    push @$tax_num, [ "Other", $other ];
  }

  return $tax_num;
}

our $organism_md5s = {}; # org => [md5s]
our $md5_abundance = {}; # md5 => abund

sub get_organism_md5s {
  my ($job, $v) = @_;

  unless (scalar(keys %$organism_md5s) > 0) {
    my $dbh  = get_analysis_dbh();
    my $rows = $dbh->selectall_arrayref("SELECT distinct organism, md5s FROM j${job}_organism_m5nr_$v");
    if ($rows && (@$rows > 0)) {
      %$organism_md5s = map { $_->[0], $_->[1] } @$rows;
    }
  }
  return $organism_md5s;
}

sub get_md5_abundance {
  my ($job, $v) = @_;

  unless (scalar(keys %$md5_abundance) > 0) {
    my $dbh  = get_analysis_dbh();
    my $rows = $dbh->selectall_arrayref("SELECT distinct md5, abundance FROM j${job}_protein_m5nr_$v");
    if ($rows && (@$rows > 0)) {
      %$md5_abundance = map { $_->[0], $_->[1] } @$rows;
    }
  }
  return $md5_abundance;
}

sub get_ontology_abundances {
  my ($job, $v) = @_;

  my $rows;
  my $data = {};
  my $ach_dbh  = get_ach_dbh();
  my $data_dbh = get_analysis_dbh();
  my $ont_nums = {};
  my $ont_md5  = {};

  $rows = $ach_dbh->selectall_arrayref("SELECT name, source FROM sources WHERE type='ontology' and name != 'GO'");
  my @sources = map { [$_->[0], lc($_->[1])] } @$rows;
  %$ont_nums  = map { $_->[0], [] } @$rows;
  
  foreach my $s (@sources) {
    $data    = {};
    $ont_md5 = {};
    my $sql  = "SELECT distinct id, level1 FROM ontology_".$s->[1];
    if ($s->[1] eq 'eggnog') {
      $sql .= " WHERE type = '".$s->[0]."'";
    }
    $rows = $ach_dbh->selectall_arrayref($sql);
    unless ($rows && (@$rows > 0)) { next; }
    %$data = map { $_->[0], $_->[1] } grep { $_->[1] && ($_->[1] =~ /\S/) } @$rows;

    $rows = $data_dbh->selectall_arrayref("SELECT distinct id, md5s FROM j${job}_ontology_m5nr_$v");
    unless ($rows && (@$rows > 0)) { next; }
    foreach my $r (@$rows) {
      if ( exists $data->{$r->[0]} ) {
	foreach my $md5 ( @{$r->[1]} ) {
	  $ont_md5->{ $data->{$r->[0]} }->{$md5} = 1;
	}
      }
    }
    my $md5s = get_md5_abundance($job, $v);
    foreach my $o (sort keys %$ont_md5) {
      my $num = 0;
      map { $num += $md5s->{$_} } grep { exists $md5s->{$_} } keys %{ $ont_md5->{$o} };
      push @{ $ont_nums->{$s->[0]} }, [ $o, $num ];
    }
  }

  return $ont_nums;
}

sub get_alpha_diversity {
  my ($job, $type) = @_;

  my $alpha = 0;
  my $h1    = 0;
  my @nums  = map { $_->[1] } @{ get_taxa_abundances($job, 'species') };
  my $sum   = sum @nums;

  unless ($sum) {
    return $alpha;
  }
  foreach my $num (@nums) {
    my $p = $num / $sum;
    if ($p > 0) { $h1 += ($p * log(1/$p)) / log(2); }
  }
  $alpha = 2 ** $h1;
  
  return $alpha;
}

sub get_rarefaction_xy {
  my ($job) = @_;

  my $rare = [];
  my $stat = get_job_statistics($job);
  unless ($stat && exists($stat->{sequence_count_raw}) && ($stat->{sequence_count_raw} > 0)) {
    return $rare;
  }

  my $nseq = $stat->{sequence_count_raw};
  my $size = ($nseq > 1000) ? int($nseq / 1000) : 1;
  my @nums = sort {$a <=> $b} map {$_->[1]} @{ get_taxa_abundances($job, 'species') };
  my $k    = scalar @nums;

  for (my $n = 0; $n < $nseq; $n += $size) {
    my $coeff = nCr2ln($nseq, $n);
    my $curr  = 0;
    map { $curr += exp( nCr2ln($nseq - $_, $n) - $coeff ) } @nums;
    push @$rare, [ $n, $k - $curr ];
  }

  return $rare;
}

# log of N choose R 
sub nCr2ln {
  my ($n, $r) = @_;

  my $c = 1;
  if ($r > $n) {
    return $c;
  }
  if (($r < 50) && ($n < 50)) {
    map { $c = ($c * ($n - $_)) / ($_ + 1) } (0..($r-1));
    return log($c);
  }
  if ($r <= $n) {
    $c = gammaln($n + 1) - gammaln($r + 1) - gammaln($n - $r); 
  } else {
    $c = -1000;
  }
  return $c;
}

# This is Stirling's formula for gammaln, used for calculating nCr
sub gammaln {
  my ($x) = @_;

  unless ($x > 0) { return 0; }
  my $s = log($x);
  return log(2 * 3.14159265458) / 2 + $x * $s + $s / 2 - $x;
}

sub get_job_stat_tags {
  return [ 'bp_count_raw',
	   'sequence_count_raw',
	   'length_max_raw',
	   'length_min_raw',
	   'average_length_raw',
	   'standard_deviation_length_raw',
	   'average_gc_content_raw',
	   'standard_deviation_gc_content_raw',
	   'average_gc_ratio_raw',
	   'standard_deviation_gc_ratio_raw',
	   'ambig_char_count_raw',
	   'ambig_sequence_count_raw',
	   'average_ambig_chars_raw',
	   'bp_count_preprocessed_rna',
	   'sequence_count_preprocessed_rna',
	   'length_max_preprocessed_rna',
	   'length_min_preprocessed_rna',
	   'average_length_preprocessed_rna',
	   'standard_deviation_length_preprocessed_rna',
	   'average_gc_content_preprocessed_rna',
	   'standard_deviation_gc_content_preprocessed_rna',
	   'average_gc_ratio_preprocessed_rna',
	   'standard_deviation_gc_ratio_preprocessed_rna',
	   'ambig_char_count_preprocessed_rna',
	   'ambig_sequence_count_preprocessed_rna',
	   'average_ambig_chars_preprocessed_rna',
	   'bp_count_preprocessed',
	   'sequence_count_preprocessed',
	   'length_max_preprocessed',
	   'length_min_preprocessed',
	   'average_length_preprocessed',
	   'standard_deviation_length_preprocessed',
	   'average_gc_content_preprocessed',
	   'standard_deviation_gc_content_preprocessed',
	   'average_gc_ratio_preprocessed',
	   'standard_deviation_gc_ratio_preprocessed',
	   'ambig_char_count_preprocessed',
	   'ambig_sequence_count_preprocessed',
	   'average_ambig_chars_preprocessed',
	   'read_count_processed_rna',
	   'sequence_count_processed_rna',
	   'clustered_sequence_count_processed_rna',
	   'cluster_count_processed_rna',
	   'read_count_processed_aa',
	   'sequence_count_processed_aa',
	   'clustered_sequence_count_processed_aa',
	   'cluster_count_processed_aa',
	   'sequence_count_sims_aa',
	   'sequence_count_sims_rna',
	   'sequence_count_ontology',
	   'sequence_count_dereplication_removed'
	 ];
}

our $preprocessed_rna_fasta = '100.preprocess.passed.fna';
our $dereplication_rm_fasta = '150.dereplication.removed.fna';
our $preprocessed_fasta     = '299.screen.passed.fna';
our $processed_fasta_rna_2  = '425.search.rna.fna';
our $processed_fasta_rna_1  = '440.cluster.rna97.fna';
our $cluster_map_rna        = '440.cluster.rna97.mapping';
our $sims_filter_rna        = '450.rna.sims.filter';
our $processed_fasta_aa_2   = '350.genecalling.coding.faa';
our $processed_fasta_aa_1   = '550.cluster.aa90.faa';
our $cluster_map_aa         = '550.cluster.aa90.mapping';
our $sims_filter_aa         = '650.superblat.sims.filter';
our $sims_ontology          = '650.superblat.expand.ontology';

sub get_result_files {
  return [ $preprocessed_rna_fasta,
	   '100.preprocess.removed.fna',
	   '150.dereplication.passed.fna',
	   $dereplication_rm_fasta,
	   $preprocessed_fasta,
	   '350.genecalling.coding.fna',
	   $processed_fasta_aa_2,
	   $processed_fasta_rna_2,
	   $processed_fasta_rna_1,
	   $cluster_map_rna,
	   '450.rna.sims',
	   $sims_filter_rna,
	   '450.rna.expand.rna',
	   $processed_fasta_aa_1,
	   $cluster_map_aa,
	   '650.superblat.sims',
	   $sims_filter_aa,
	   '650.superblat.expand.protein',
	   $sims_ontology,
	   '900.loadDB.sims.filter.seq',
	   '900.loadDB.source.stats'
	 ];
}

sub get_compress_suffixes {
  return [ 'fastq',
	   'fq',
	   'fasta',
	   'fna',
	   'faa',
	   'sims',
	   'filter',
	   'protein',
	   'ontology',
	   'rna',
	   'lca'
	 ];
}

1;
