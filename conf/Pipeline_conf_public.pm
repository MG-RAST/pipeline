package Pipeline_conf_public;

use strict;
use warnings;
no warnings('once');


# keywords and values for workflow template
our $template_keywords = {
    
    # versions
    'pipeline_version'   => "3.5",
    'ach_sequence_ver'   => "7",
    'ach_annotation_ver' => "1",
	
    # default options
    'prefix_length' => '50',
    'fgs_type'      => '454',
    'aa_pid'        => '90',
    'rna_pid'       => '97',
    'm5rna_clust'   => "md5nr.clust",
	
    
    # shock data download urls
	
	'm5nr_diamond_resource'	=> {	"resource" => "shock",
									"host" => "http://shock.metagenomics.anl.gov",
									"node" => "73abdf1a-9f91-4b06-b19c-8b326f82a8bd"}
	
    #'m5nr1_download_url' => "http://shock.metagenomics.anl.gov/node/4406405c-526c-4a63-be22-04b7c2d18434?download",
    #'m5nr2_download_url' => "http://shock.metagenomics.anl.gov/node/65d644a8-55a5-439f-a8b5-af1440472d8d?download",
    'm5rna_download_url' => "http://shock.metagenomics.anl.gov/node/1284813a-91d1-42b1-bc72-e74f19e1a0d1?download",
    'm5rna_clust_download_url' => "http://shock.metagenomics.anl.gov/node/c4c76c22-297b-4404-af5c-8cd98e580f2a?download",

    'm5nr_annotation_url' => "http://shock.metagenomics.anl.gov/node/e5dc6081-e289-4445-9617-b53fdc4023a8?download",    


};

# shock urls for bowtie index download
our $shock_bowtie_url = "http://shock.metagenomics.anl.gov";
our $shock_bowtie_indexes = {
    'a_thaliana'     => {
                            'a_thaliana.1.bt2' => 'fd2589fe-2829-4978-a395-55577c4a37bc',
                            'a_thaliana.2.bt2' => '5510e806-f602-4651-8361-a448131fcb8e',
                            'a_thaliana.3.bt2' => '155d3339-9d72-43fc-925b-04be3101bf51',
                            'a_thaliana.4.bt2' => '27d9e7fb-ff58-4d67-bf94-a4b044c3a979',
                            'a_thaliana.rev.1.bt2' => 'f9ab0db6-265c-4cda-872f-d7673091f3b1',
                            'a_thaliana.rev.2.bt2' => 'b05fe2b1-8af5-4591-8994-7d25388fd911'
                        },
    'b_taurus'       => {
                            'b_taurus.1.bt2' => '1c8f03be-3f82-433f-9499-39b88f01fbaa',
                            'b_taurus.2.bt2' => 'd13be172-6055-4d1e-8523-ae463dccfc7e',
                            'b_taurus.3.bt2' => 'b79e0584-02b7-403e-af60-1344c6f68309',
                            'b_taurus.4.bt2' => '516d5c61-0f41-467c-83b4-673f71dcb9a3',
                            'b_taurus.rev.1.bt2' => 'd30faffa-436b-4626-9cc3-b6aebdf7a919',
                            'b_taurus.rev.2.bt2' => '5b57ddb0-695d-41c8-818f-2eed77c4e7e0'
                        },
    'd_melanogaster' => {
                            'd_melanogaster.1.bt2' => 'b2b58ae0-afbc-4b82-a24d-cd9aabe5aba1',
                            'd_melanogaster.2.bt2' => '0582ada2-b4dd-405d-b053-a1debf381deb',
                            'd_melanogaster.3.bt2' => 'c0f5854d-2b17-4ed7-ad6e-63f49ab6e455',
                            'd_melanogaster.4.bt2' => '987571de-7aa5-427d-a8e5-a10c5ba6871b',
                            'd_melanogaster.rev.1.bt2' => 'e6963ad1-c3e1-4175-a251-ba4502fa6303',
                            'd_melanogaster.rev.2.bt2' => 'acc9b5f9-4a57-461b-be37-039bb2f6ce8f'
                        },
    'e_coli'         => {
                            'e_coli.1.bt2' => '66fe2976-80fd-4d67-a5cd-051018c49c2b',
                            'e_coli.2.bt2' => 'd0eb4784-2f4a-4093-8731-5fe158365036',
                            'e_coli.3.bt2' => '75acfaea-bc42-4f02-a014-cdff9f025e2e',
                            'e_coli.4.bt2' => 'f85b745c-0bea-4bac-9fa4-530411f3bc1c',
                            'e_coli.rev.1.bt2' => '94e7b176-034f-4297-957e-cbcaa7cbc583',
                            'e_coli.rev.2.bt2' => 'd0e023b1-7ada-4d10-beda-9db9a681ed57'
                        },
    'h_sapiens'      => {
                            'h_sapiens.1.bt2' => '12c7a5dc-7859-43cb-a7a0-42a7d2ec3d29',
                            'h_sapiens.2.bt2' => '87eeeac0-b3df-4872-9a71-8f5a984a78f0',
                            'h_sapiens.3.bt2' => 'ea8914ab-7425-401f-9a86-5e10210e10b4',
                            'h_sapiens.4.bt2' => '95da2457-d214-4357-b039-47ef84387ae6',
                            'h_sapiens.rev.1.bt2' => '88a60d6f-8281-4b77-b86e-c8ca8b21b049',
                            'h_sapiens.rev.2.bt2' => 'bd6a2f1d-87fb-42eb-a1ce-fb506b8da65a'
                        },
    'm_musculus'     => {
                            'm_musculus.1.bt2' => '15ff76c8-fab4-41ac-83ec-e41c75577451',
                            'm_musculus.2.bt2' => '8d2e1fb0-fde2-4d23-b0e3-9538d4c3cfd0',
                            'm_musculus.3.bt2' => 'd5b42419-45db-400b-9dad-88b63e4fdcab',
                            'm_musculus.4.bt2' => '6176d3bc-4935-408b-a8aa-e620091915d5',
                            'm_musculus.rev.1.bt2' => 'c2e2e1dc-2e41-40ef-b132-ae985c55b082',
                            'm_musculus.rev.2.bt2' => '18ac35ba-f4e5-474c-9731-cb404d31a793'
                        },
    's_scrofa'       => {
                            's_scrofa.1.bt2' => 'fba406ba-451c-4fbc-a5b7-86fd506856f3',
                            's_scrofa.2.bt2' => 'cf9ff454-acda-425d-b8ef-3a5a9b27da5c',
                            's_scrofa.3.bt2' => '00d8262f-7131-497d-a694-85fb1c165dcb',
                            's_scrofa.4.bt2' => '4c011cd7-4bb5-40ba-8a9e-3a7436ec1f51',
                            's_scrofa.rev.1.bt2' => '9cbbc2a4-fbd9-4c8e-9423-82f1e693387a',
                            's_scrofa.rev.2.bt2' => 'a01e41ab-f3e4-439a-a9c6-0bf39ff8e787'
                        }
};
