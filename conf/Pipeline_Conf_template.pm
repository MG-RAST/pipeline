package Pipeline_Conf;

use strict;
use warnings;
no warnings('once');

our $pipeline_version = "";

# file location
our $data_dir = "";
our $md5rna_full = $data_dir."/md5rna/current/md5nr";
our $md5rna_clust = $data_dir."/md5rna/current/md5nr.clust";
our $global_job_dir = "";
our $global_dir = "";
our $cluster_tmp = "";
our $cluster_workspace = "";
our $local_tmp = "";
our $local_workspace = "";
our $incoming_dir   = "";
our $global_log_dir = $global_dir."/logs";

# memcache
our $memcache_host = "";
our $memcache_key  = "_ach";

# mysql certificate files
our $mysql_client_key = "";
our $mysql_client_cert = "";
our $mysql_ca_file = "";

# jobcache db
our $jobcache_db   = "";
our $jobcache_host = "";
our $jobcache_user = "";
our $jobcache_password = "";

# analysis db
our $analysis_db   = "";
our $analysis_host = "";
our $analysis_user = "";
our $analysis_password = "";
our $analysis_db_table_range = 5000;

# ACH db
our $ach_db   = "";
our $ach_host = "";
our $ach_user = "";
our $ach_annotation_ver = '';
our $ach_sequence_ver   = '';

# WebApp (user) db
our $webapp_db   = '';
our $webapp_host = ''; # 'bio-app-authdb.mcs.anl.gov';
our $webapp_user = '';
our $webapp_password = '';

# bowtie indexes
our $bowtie_indexes = $data_dir."/bowtie/index";
our $bowtie_stageid = { a_thaliana            => 201,
			b_taurus              => 202,
			d_melanogaster_fb5_22 => 203,
			e_coli                => 204,
			h_sapiens_asm         => 205,
			m_musculus_ncbi37     => 206
		      };

# Pipeline
our $min_gene_size  = 1024;
our $results_dir    = "analysis";
our $torque_logs    = $global_log_dir.'/torque_logs';
our $torque_options = "-j oe -o $torque_logs -m n"; 
our $pipeline = {};

$pipeline->{'default'} = [{ id           => '075',
			    name         => "qc",
			    script       => "pipeline_qc",
			    args         => '-j <job_num> -s <job_dir>/raw/<job_num>.<file_type> -n raw -p 4 -k <kmers>',
			    nodes        => 1,
			    ppn          => 4,
			    walltime     => "72:00:00",
			    file_type    => "fna",
			    kmers        => "6,15"
			  },
			  { id             => 100,
			    name           => "preprocess",
			    script         => "pipeline_preprocess",
			    args           => "-j <job_num> -f <job_dir>/raw/<job_num>.<file_type> -o <filter_options>",
			    nodes          => 1,
			    ppn            => 1,
			    walltime       => "24:00:00",
			    filter_options => "",
			    file_type      => "fna"
			  },
			  { id            => 150,
			    name          => "dereplication",
			    script        => "pipeline_dereplication",
			    args          => "-j <job_num> -f <job_dir>/analysis/100.preprocess.passed.fna -prefix_length <prefix_length> -r <dereplicate>",
			    nodes         => 1,
			    ppn           => 1,
			    walltime      => "24:00:00",
			    requires      => ["preprocess"],
			    prefix_length => 50,
			    dereplicate   => 1
			  },
			  { id             => 299,
			    name           => "screen",
			    script         => "pipeline_screen",
			    args           => "-j <job_num> -f <job_dir>/analysis/150.dereplication.passed.fna -i <screen_indexes> -t 8 -r <bowtie>",
			    nodes          => 1,
			    ppn            => 4,
			    walltime       => "24:00:00",
			    requires       => ["dereplication"],
			    screen_indexes => "h_sapiens_asm",
			    bowtie         => 1
			  },
			  { id           => 350,
			    name         => "genecalling",
			    script       => "pipeline_genecalling",
			    args         => "-j <job_num> -f <job_dir>/analysis/299.screen.passed.fna -p 4",
			    nodes        => 1,
			    ppn          => 4,
			    walltime     => "24:00:00",
			    requires     => ["screen"]
			  },
			  { id           => 425,
			    name         => "search",
			    script       => "pipeline_search",
			    args         => "-j <job_num> -f <job_dir>/analysis/100.preprocess.passed.fna -r $md5rna_clust -p 4",
			    nodes        => 1,
			    ppn          => 4,
			    walltime     => "24:00:00",
			    requires     => ["preprocess"]
			  },
			  { id           => 440,
			    name         => "cluster_rna97",
			    script       => "pipeline_cluster",
			    args         => "-j <job_num> -f <job_dir>/analysis/425.search.rna.fna -<seq_type> -p <pid>",
			    nodes        => 1,
			    ppn          => 1,
			    walltime     => "24:00:00",
			    requires     => ["search"],
			    seq_type     => "rna",
			    pid          => "97"
			  },
			  { id           => 450,
			    name         => "rna",
			    script       => "pipeline_rna",
			    args         => "-j <job_num> -f <job_dir>/analysis/440.cluster.rna97.fna -r /local/data_cache/md5rna/current/md5nr",
			    nodes        => 1,
			    ppn          => 1,
			    walltime     => "24:00:00",
			    requires     => ["cluster_rna97"]
			  },
			  { id           => 550,
			    name         => "cluster_aa90",
			    script       => "pipeline_cluster",
			    args         => "-j <job_num> -f <job_dir>/analysis/350.genecalling.coding.faa -<seq_type> -p <pid>",
			    nodes        => 1,
			    ppn          => 1,
			    walltime     => "24:00:00",
			    requires     => ["genecalling"],
			    seq_type     => "aa",
			    pid          => "90"
			  },
			  { id           => 640,
			    name         => "loadAWE",
			    script       => "pipeline_loadAWE",
			    args         => "-j <job_num> -f <job_dir>/analysis/550.cluster.aa90.faa",
			    nodes        => 1,
			    ppn          => 1,
			    walltime     => "24:00:00",
			    requires     => ["cluster_aa90"],
			    setspri      => 1000
			  },
			  { id           => 650,
			    name         => "sims",
			    script       => "pipeline_sims",
			    args         => "-j <job_num> -f <job_dir>/analysis/550.cluster.aa90.faa",
			    nodes        => 1,
			    ppn          => 1,
			    walltime     => "24:00:00", 
			    qsub_options => "-h",
			    requires     => []
			  },
			  { id           => 900,
			    name         => "loadDB",
			    script       => "pipeline_loadDB",
			    args         => '-j <job_num> -f <job_dir>/raw/<job_num>.<file_type> -p <job_dir>/analysis/650.superblat -r <job_dir>/analysis/450.rna -c <job_dir>/analysis/550.cluster.aa90.mapping -m <job_dir>/analysis/440.cluster.rna97.mapping -d',
			    nodes        => 1,
			    ppn          => 1,
			    walltime     => "24:00:00",
			    file_type    => "fna",
			    requires     => ["sims", "rna"]
			  },
			  { id           => 999,
			    name         => "done",
			    script       => "pipeline_done",
			    args         => '-j <job_num> -r <job_dir>/raw/<job_num>.<file_type>',
			    nodes        => 1,
			    ppn          => 1,
			    walltime     => "24:00:00",
			    file_type    => "fna",
			    requires     => ["loadDB"],
			    setspri      => 1000
			  }];

