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
  $dbh = DBI->connect("DBI:mysql:database=".$Pipeline_Conf::jobcache_db.";host=".$Pipeline_Conf::jobcache_host.";mysql_ssl=1;mysql_ssl_client_key=".$Pipeline_Conf::mysql_client_key.";mysql_ssl_client_cert=".$Pipeline_Conf::mysql_client_cert.";mysql_ssl_ca_file=".$Pipeline_Conf::mysql_ca_file,
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
  my $dbh = DBI->connect("DBI:mysql:database=".$Pipeline_Conf::webapp_db.";host=".$Pipeline_Conf::webapp_host.";mysql_ssl=1;mysql_ssl_client_key=".$Pipeline_Conf::mysql_client_key.";mysql_ssl_client_cert=".$Pipeline_Conf::mysql_client_cert.";mysql_ssl_ca_file=".$Pipeline_Conf::mysql_ca_file, 
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

sub get_job_project_name {
  my $job = shift;
  my $dbh = get_jobcache_dbh();
  my $query = $dbh->prepare(qq(select Project.name from Project, Job, ProjectJob where Job.job_id = ? and Job._id = ProjectJob.job and ProjectJob.project = Project._id));
  $query->execute($job);
  my $ref = $query->fetchrow_arrayref;
  return $ref->[0];
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
  my ($job, $data, $proc_subdir) = @_;
  return set_job_tag_data($job, $data, "JobAttributes", $proc_subdir);
}

sub set_job_statistics {
  my ($job, $data, $proc_subdir) = @_;
  return set_job_tag_data($job, $data, "JobStatistics", $proc_subdir);
}

sub set_job_tag_data {
  my ($job, $data, $table, $proc_subdir) = @_;

  if($Pipeline_Conf::jobcache_db_avail == 1) {
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
  } else {
    my $job_dir = get_job_dir($job);
    my $ofile = "$job_dir/proc/$proc_subdir/$table.out";
    open OUT, ">>$ofile" || die "Cannot print to file: $ofile\n";
    unless ($data && @$data) {
      return 0;
    }
    foreach my $set (@$data) {
      my ($tag, $val) = @$set;
      print OUT "insert into $table (`tag`,`value`,`job`,`_job_db`) values (\'$tag\',$val,(select _id from Job where job_id = $job),2) on duplicate key update value=$val;\n";
    }
    close OUT;
  }
  return 1;
}

sub update_stage_info { 
  my ($job, $stage, $status) = @_;
  if($Pipeline_Conf::jobcache_db_avail == 1) {
    my $dbh = get_jobcache_dbh();
    my $query = $dbh->prepare(qq(select * from Job where job_id=?));
    $query->execute($job) or die $dbh->errstr;  
    my $job_object = $query->fetchrow_hashref;  
    $query = $dbh->prepare(qq(insert into PipelineStage (`stage`,`status`,`job`,`_job_db`,`timestamp`) values (?,?,?,2,CURRENT_TIMESTAMP) on duplicate key update status=?));
    $query->execute($stage,$status,$job_object->{_id},$status) or die $dbh->errstr;
  }
  return 1;
}

sub update_stage_info_if_progressed { 
  my ($job, $stage, $status) = @_;
  my %pipeline_stage_to_order_number = ( 'upload'        => 0,
                                         'preprocess'    => 1,
                                         'dereplication' => 2,
                                         'screen'        => 3,
                                         'genecalling'   => 4,
                                         'cluster_aa90'  => 5,
                                         'loadAWE'       => 6,
                                         'sims'          => 7,
                                         'loadDB'        => 8,
                                         'done'          => 9 );

  if($Pipeline_Conf::jobcache_db_avail == 1) {
    my $dbh = get_jobcache_dbh();
    my $query = $dbh->prepare(qq(select * from Job where job_id=?));
    $query->execute($job) or die $dbh->errstr;  
    my $job_object = $query->fetchrow_hashref;  

    $query = $dbh->prepare(qq(select * from PipelineStage where job=?));
    $query->execute($job_object->{_id}) or die $dbh->errstr;

    my $pipeline_stage_object = $query->fetchrow_hashref;
    my $prev_stage = $pipeline_stage_object->{stage};

    if(!exists $pipeline_stage_to_order_number{$stage} || !exists $pipeline_stage_to_order_number{$prev_stage} || $pipeline_stage_to_order_number{$stage} >= $pipeline_stage_to_order_number{$prev_stage}) {
      $query = $dbh->prepare(qq(insert into PipelineStage (`stage`,`status`,`job`,`_job_db`,`timestamp`) values (?,?,?,2,CURRENT_TIMESTAMP) on duplicate key update status=?));
      $query->execute($stage,$status,$job_object->{_id},$status) or die $dbh->errstr;
    }
  }
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

sub get_source_map {
    my $data_dbh = get_analysis_dbh();
    my $rows = $data_dbh->selectall_arrayref("SELECT _id, name FROM sources");
    unless ($rows && (@$rows > 0)) { return {}; }
    my %data = map { $_->[0], $_->[1] } @$rows;
    return \%data;
}

sub get_function_abundances {
  my ($job, $v) = @_;

  my $data = {}; # id => function
  my $data_dbh = get_analysis_dbh();
  my $func_md5  = {}; # function => { md5s }
  my $func_num  = []; # [ function, abundance ]

  my $rows = $data_dbh->selectall_arrayref("SELECT _id, name FROM functions");
  unless ($rows && (@$rows > 0)) { return []; }
  %$data = map { $_->[0], $_->[1] } grep { $_->[1] && ($_->[1] =~ /\S/) } @$rows;
  
  my $funcs = get_function_md5s($job, $v);
  foreach my $f (keys %$funcs) {
    if (exists $data->{$f}) {
      map { $func_md5->{$data->{$f}}->{$_} = 1 } @{ $funcs->{$f} };
    }
  }

  my $md5s  = get_md5_abundance($job, $v);
  my $other = 0;
  foreach my $f (sort keys %$func_md5) {
    my $num = 0;
    map { $num += $md5s->{$_} } grep { exists $md5s->{$_} } keys %{ $func_md5->{$f} };
    if ($num > 0) {
      push @$func_num, [ $f, $num ];
    }
  }

  return $func_num;
}

sub get_taxa_abundances {
  my ($job, $taxa, $clump, $v) = @_;

  my $data = {}; # id => taxa
  my $data_dbh = get_analysis_dbh();
  my $tax_md5  = {}; # taxa => { md5s }
  my $tax_num  = []; # [ taxa, abundance ]

  my $rows = $data_dbh->selectall_arrayref("SELECT distinct _id, tax_$taxa FROM organisms_ncbi");
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

our $ontology_md5s = {}; # src => ont => [md5s]
our $function_md5s = {}; # func => [md5s]
our $organism_md5s = {}; # org => [md5s]
our $md5_abundance = {}; # md5 => abund

sub get_ontology_md5s {     
  my ($job, $v) = @_;
  
  unless (scalar(keys %$ontology_md5s) > 0) {
    my $dbh  = get_analysis_dbh();
    my $sql  = "SELECT distinct s.name, j.id, j.md5s FROM job_ontologies j, sources s WHERE j.version=$v AND j.job=$job AND j.source=s._id";
    my $rows = $dbh->selectall_arrayref($sql);
    if ($rows && (@$rows > 0)) {
      map { $ontology_md5s->{$_->[0]}{$_->[1]} = $_->[2] } @$rows;
    }
  }
  return $ontology_md5s;
}

sub get_function_md5s {
  my ($job, $v) = @_;

  unless (scalar(keys %$function_md5s) > 0) {
    my $dbh  = get_analysis_dbh();
    my $rows = $dbh->selectall_arrayref("SELECT distinct id, md5s FROM job_functions WHERE version=$v AND job=$job");
    if ($rows && (@$rows > 0)) {
      %$function_md5s = map { $_->[0], $_->[1] } @$rows;
    }
  }
  return $function_md5s;
}

sub get_organism_md5s {
  my ($job, $v) = @_;

  unless (scalar(keys %$organism_md5s) > 0) {
    my $dbh  = get_analysis_dbh();
    my $rows = $dbh->selectall_arrayref("SELECT distinct id, md5s FROM job_organisms WHERE version=$v AND job=$job");
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
    my $rows = $dbh->selectall_arrayref("SELECT distinct md5, abundance FROM job_md5s WHERE version=$v AND job=$job");
    if ($rows && (@$rows > 0)) {
      %$md5_abundance = map { $_->[0], $_->[1] } @$rows;
    }
  }
  return $md5_abundance;
}

sub get_ontology_abundances {
  my ($job, $v) = @_;

  my $data = {}; # src => id => level1
  my $data_dbh = get_analysis_dbh();
  my $ont_md5  = {}; # src => lvl1 => { md5s }
  my $ont_nums = {}; # src => [ lvl1, abundance ]

  my $sql  = "SELECT distinct s.name, o._id, o.level1 FROM ontologies o, sources s WHERE o.source=s._id";
  my $rows = $data_dbh->selectall_arrayref($sql);
  unless ($rows && (@$rows > 0)) { return {}; }
  map { $data->{$_->[0]}{$_->[1]} = $_->[2] } grep { $_->[2] && ($_->[2] =~ /\S/) } @$rows;
  
  my $onts = get_ontology_md5s($job, $v);
  foreach my $s (keys %$onts) {
    foreach my $o (keys %{$onts->{$s}}) {
      if (exists $data->{$s}{$o}) {
        map { $ont_md5->{$s}{$data->{$s}{$o}}->{$_} = 1 } @{ $onts->{$s}{$o} };
      }
    }
  }

  my $md5s = get_md5_abundance($job, $v);
  foreach my $s (sort keys %$ont_md5) {
    foreach my $d (sort keys %{$ont_md5->{$s}}) {
      my $num = 0;
      map { $num += $md5s->{$_} } grep { exists $md5s->{$_} } keys %{ $ont_md5->{$s}{$d} };
      if ($num > 0) {
  	    push @{$ont_nums->{$s}}, [ $d, $num ];
      }
    }
  }
  
  return $ont_nums;
}

sub get_alpha_diversity {
  my ($job, $type, $v) = @_;

  my $alpha = 0;
  my $h1    = 0;
  my @nums  = map { $_->[1] } @{ get_taxa_abundances($job, 'species', undef, $v) };
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
  my ($job, $v) = @_;

  my $rare = [];
  my $stat = get_job_statistics($job);
  unless ($stat && exists($stat->{sequence_count_raw}) && ($stat->{sequence_count_raw} > 0)) {
    return $rare;
  }

  my $nseq = $stat->{sequence_count_raw};
  my $size = ($nseq > 1000) ? int($nseq / 1000) : 1;
  my @nums = sort {$a <=> $b} map {$_->[1]} @{ get_taxa_abundances($job, 'species', undef, $v) };
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
	   $processed_fasta_aa_1,
	   $cluster_map_aa,
	   '650.superblat.sims',
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
	   'mapping',
	   'filter',
	   'protein',
	   'ontology',
	   'rna',
	   'lca'
	 ];
}

1;
