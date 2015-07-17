package Pipeline_conf_private;

use strict;
use warnings;
no warnings('once');

my $BASE = "/homes/.../git/pipeline"; #"/mcs/bio/mg-rast/prod/pipeline";

# default variables
our $awe_url = "";
our $awe_pipeline_token = '';
our $awe_token_prefix = '';
our $shock_pipeline_token = '';
our $shock_token_prefix = '';
our $template_file = $BASE."/conf/mgrast-prod.awe.template";
our $temp_dir = $BASE."/temp";

# jobcache db for submission
our $job_dbhost = "";
our $job_dbname = "JobDB";
our $job_dbuser = "pipeline";
our $job_dbpass = "";

# analysis db
our $analysis_dbhost = "";
our $analysis_dbname = "mgrast_analysis";
our $analysis_dbuser = "";
our $analysis_dbpass = "";

# ach mongo db
our $ach_mongo_host = "";
our $ach_mongo_name = "m5nr";
our $ach_mongo_user = "";
our $ach_mongo_pass = "";

# keywords and values for workflow template
our $template_keywords = {
    
    # awe clients
    'clientgroups' => "docker",
    'priority' => 1,
    
    # mgrast api
    'mgrast_api' => "http://api.metagenomics.anl.gov",
    'api_key'    => "",
    
    # service urls
    'solr_url'  => "",
    'solr_col'  => "",
    'shock_url' => "http://shock.metagenomics.anl.gov",
	
    # client certificates in shock
    'cert_shock_url'  => "",
    'mysql_cert'      => "",
    'postgresql_cert' => "",
    
	
    # jobcache db for pipeline
    'job_dbhost' => $job_dbhost,
    'job_dbname' => $job_dbname,
    'job_dbuser' => $job_dbuser,
    'job_dbpass' => $job_dbpass,
    
    # analysis db
    'analysis_dbhost' => $analysis_dbhost,
    'analysis_dbname' => $analysis_dbname,
    'analysis_dbuser' => $analysis_dbuser,
    'analysis_dbpass' => $analysis_dbpass,


};
