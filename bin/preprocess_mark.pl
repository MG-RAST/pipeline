#!/usr/bin/env perl

use strict;
use warnings; 

use URI::Escape;
use File::Basename;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use Getopt::Long;
use DirHandle;

use Pipeline_Conf;
use Data::Dumper;

use strict;

umask 000;

$Data::Dumper::Terse  = 1;
$Data::Dumper::Indent = 1;

my $verbose = 1;

# read in parameters
my $user_dir        = '';
my $upload_dir      = '';
my $upload_filename = '';
my $demultiplex     = 0;
my $partitioned     = 0;

GetOptions ( 
	     'user_dir=s'        => \$user_dir,
	     'upload_dir=s'      => \$upload_dir,
	     'upload_filename=s' => \$upload_filename,
	     'demultiplex:i'     => \$demultiplex,
	     'partitioned:i'     => \$partitioned,
	   );

my $base_dir    = "$Pipeline_Conf::incoming_dir";
my $status_file = "$base_dir/logs/upload.status";

$verbose && &print_message("preprocess: user_dir=$user_dir upload_dir=$upload_dir upload_filename=$upload_filename demultiplex=$demultiplex partitioned=$partitioned");

if ( $demultiplex )
{
    &demultiplex_file($user_dir, $upload_dir, $upload_filename);
}
else
{
    if ( $partitioned )
    {
	&reconstitute_file($user_dir, $upload_dir, $upload_filename);
    }

    &preprocess_file($user_dir, $upload_dir, $upload_filename);
}

$verbose && &print_message("preprocess: done");

sub reconstitute_file {
    my($user_dir, $upload_dir, $upload_filename) = @_;

    my $dir = "$base_dir/$user_dir/$upload_dir";

    # partitioned files are named with the upload filename prefix followed by a zero-based integer extension
    # e.g. the upload file x.fna will be partitioned into x.fna.0, x.fna.1, x.fna.2, ...
    
    opendir(DIR, $dir) or die "could not open directory '$dir': $!";
    my @files = grep {/^$upload_filename\.\d+$/} readdir(DIR);
    closedir(DIR);

    my @indexed = ();
    foreach my $file ( @files )
    {
	$file =~ /^$upload_filename\.(\d+)$/;
	push @indexed, [$file, $1];
    }

    foreach my $rec ( sort {$a->[1] <=> $b->[1]} @indexed )
    {
	my $file = $rec->[0];
	open(PART, "<$dir/$file") or die "could not open file '$dir/$file': $!";
	open(NEW, ">>$dir/$upload_filename") or die "could not open file '$dir/$upload_filename': $!";

	my($buf, $n, $bytes);
	while (($n = read(PART, $buf, 4096)))
	{
	    print NEW $buf;
	}

	close(NEW) or die "could not close file '$dir/$upload_filename': $!";
	close(PART) or die "could not close file '$dir/$file': $!";

	chmod 0666, "$dir/$upload_filename";
    }
}

sub demultiplex_file {
    my($user_dir, $upload_dir, $upload_filename) = @_;

    my $filerec  = &read_processed_log($base_dir, $user_dir, $upload_dir);
    my $mid_tags = &read_mid_tags_file($base_dir, $user_dir, $upload_dir, $upload_filename);

    &mark_status($status_file, $user_dir, $upload_dir, $upload_filename, 'demultiplexing_started');
    $verbose && &print_message("start:\tdemultiplex fasta file '$upload_filename' with MID tags '" . join(',', @$mid_tags));

    # multiplexed file, report original file data before demultiplexing
    my $file_eol    = $filerec->{$upload_filename}{file_eol};
    my $file_path   = $filerec->{$upload_filename}{file_path};
    my $target_dir  = "$file_path/$upload_filename.MID_extract";

    mkdir($target_dir);
    chmod 0777, $target_dir;

    my $files = &split_fasta_by_mid_tag($upload_filename, $file_path, $file_eol, $target_dir, $mid_tags);

    $verbose && &print_message("done:\tdemultiplex fasta file");

    # get basic file data -- name, size etc.
    # $file from @$files includes complete path
    foreach my $file ( @$files )
    {
	$verbose && &print_message("start:\tfile tests, $file");

	# $file_path etc. here refers to file created from demultiplexed data, outside this loop it refers to upload_file -- not good
	my $file_size     = -s $file;
	next if ($file_size == 0);  # the no_MID_tag file may be zero size, as well as some MID tags for which no sequence is found

	my($file_base, $file_path, $file_suffix) = fileparse($file, qr/\.[^.]*$/);
	my $file_name     = $file_base . $file_suffix;
	my $file_type     = &file_type($file_name, $file_path);
	my $file_eol      = &file_eol($file_type);
	my $file_format   = &file_format($file_name, $file_path, $file_type, $file_suffix, $file_eol);
	my($file_md5)     = (`md5sum '$file'` =~ /^(\S+)/);

	$filerec->{$file_name} = {
	                           'file_upload'   => $upload_filename,
				   'file_name'     => $file_name,
				   'file_base'     => $file_base,
				   'file_path'     => $file_path,
				   'file_suffix'   => $file_suffix,
				   'file_type'     => $file_type,
				   'file_eol'      => $file_eol,
				   'file_format'   => $file_format,
				   'file_md5'      => $file_md5,
				   'file_size'     => $file_size,
			       };
	$filerec->{$file_name}{file_seq_type} = &file_seq_type($file_name, $file_path, $file_eol);
	$filerec->{$file_name}{file_report}   = &fasta_report_and_stats($file_name, $file_path, $filerec);

	&mark_status($status_file, $user_dir, $upload_dir, $file_name, 'from_demultiplexing');
	$verbose && &print_message("done:\tfile tests");
    }

    my $file_log = "$base_dir/$user_dir/$upload_dir/processed_files";

    open(FL, ">$file_log") or die "could not open file '$file_log': $!";
    print FL Dumper($filerec);
    close(FL) or die "could not close file '$file_log': $!";

    chmod 0666, $file_log;

    &mark_status($status_file, $user_dir, $upload_dir, $upload_filename, 'demultiplexing_completed');
    $verbose && &print_message("done:\tdemultiplex fasta file");
}

sub preprocess_file {
    my($user_dir, $upload_dir, $upload_filename) = @_;

    my $ts;
    &mark_status($status_file, $user_dir, $upload_dir, $upload_filename, 'processing_started');
    $verbose && &print_message("start:\tpreprocessing, $upload_filename");

    my $user_upload_dir = "$base_dir/$user_dir/$upload_dir";

    my $log_file = "$user_upload_dir/logfile";
    open(LOG, ">>$log_file") or die "could not open file '$log_file': $!";
    flock(LOG, 1) or die "could not create shared lock for file '$log_file': $!";

    $ts = &timestamp;
    print LOG "\nprocessing\tstarted\t$ts\n";

    # handle compressed files, create list of files extracted from uploaded files

    $verbose && &print_message("start:\tunpacking, $upload_filename");

    # my $files = &unpack_file($upload_filename, $user_upload_dir, \*LOG);
    my $files = ['/mcs/bio/mg-rast/prod/incoming/94c408aa242820bc2e21fecdf07554b2/2011.08.04.10.00.39/Serafuli_forwardreads.txt.zip.extract/Serafuli_forwardreads.txt'];
    
    $verbose && &print_message("done:\tunpacking");

    # create hash to store all file information
    my $filerec = {};

    # get basic file data -- name, size etc.
    # $file from @$files includes complete path
    foreach my $file ( @$files )
    {
	$verbose && &print_message("start:\tfile tests, $file");

	my($file_base, $file_path, $file_suffix) = fileparse($file, qr/\.[^.]*$/);
	my $file_name     = $file_base . $file_suffix;
	my $file_type     = &file_type($file_name, $file_path);
	my $file_eol      = &file_eol($file_type);
	my $file_format   = &file_format($file_name, $file_path, $file_type, $file_suffix, $file_eol);
	my($file_md5)     = (`md5sum '$file'` =~ /^(\S+)/);
	my $file_size     = -s $file;

	$filerec->{$file_name} = {
	                           'file_upload'   => $upload_filename,
				   'file_name'     => $file_name,
				   'file_base'     => $file_base,
				   'file_path'     => $file_path,
				   'file_suffix'   => $file_suffix,
				   'file_type'     => $file_type,
				   'file_eol'      => $file_eol,
				   'file_format'   => $file_format,
				   'file_md5'      => $file_md5,
				   'file_size'     => $file_size,
			       };

	if ( $file_name =~ /([^a-zA-Z0-9._-])/ )
	{
	    my $badchar = $1;
	    $filerec->{$file_name}{error} = "file name contains '$badchar' character, please use alphanumeric and .-_ characters only";
	    $verbose && &print_message("error:\tfile name '$file_name' contains '$badchar' character");
	}

	$verbose && &print_message("done:\tfile tests");
    }

    # get file sequence type
    foreach my $file_name ( keys %$filerec )
    {
	if ( $filerec->{$file_name}{file_format} eq 'fasta' )
	{
	    $verbose && &print_message("start:\tfile sequence type test (DNA/protein), $file_name");

	    my $file_eol  = $filerec->{$file_name}{file_eol};
	    my $file_path = $filerec->{$file_name}{file_path};
	    $filerec->{$file_name}{file_seq_type} = &file_seq_type($file_name, $file_path, $file_eol);

	    $verbose && &print_message("done:\tfile sequence type test (DNA/protein)");
	}
    }


    # handle fastq files
    my @fastq_files = grep {$filerec->{$_}{file_format} eq 'fastq'} keys %$filerec;

    foreach my $fastq_file ( @fastq_files )
    {
	my $fasta_file = "$fastq_file.fasta";
	$verbose && &print_message("start:\tfasta extraction from fastq, $fastq_file");

	my $file_path = $filerec->{$fastq_file}{file_path};
    
	if ( &extract_fasta_from_fastq($fastq_file, $fasta_file, $file_path, $filerec->{$fastq_file}{file_eol}) ) 
	{
	    $filerec->{$fastq_file}{fq2fa} = $fasta_file;

	    my $fasta_file_size = -s "$file_path/$fasta_file";
	    my($fasta_file_md5) = (`md5sum '$file_path/$fasta_file'` =~ /^(\S+)/);

	    $filerec->{$fasta_file}  = {
		                         'file_upload'   => $upload_filename,
					 'file_name'     => $fasta_file,
					 'file_base'     => $fastq_file,
					 'file_path'     => $file_path,
					 'file_suffix'   => '.fasta',
					 'file_type'     => 'ASCII text',
					 'file_eol'      => $/,
					 'file_format'   => 'fasta',
					 'file_seq_type' => 'DNA',
					 'fastq_file'    => $fastq_file,
					 'file_md5'      => $fasta_file_md5,
					 'file_size'     => $fasta_file_size,
				     };

	    $filerec->{$fastq_file}{fasta_file} = $fasta_file;
	} 
	else 
	{
	    # log error
	    die "could not extract fasta sequence file from fastq '$fastq_file'";
	}

	$verbose && &print_message("done:\tfasta extraction from fastq, $fastq_file");
    }

    # handle sff files
    my @sff_files = grep {$filerec->{$_}{file_format} eq 'sff'} keys %$filerec;

    foreach my $sff_file ( @sff_files )
    {
	my $fasta_file = $sff_file . '.fasta';
	my $qual_file  = $sff_file . '.qual';
	
	$verbose && &print_message("start:\tfasta extraction from sff, $sff_file");
	
	my $file_path = $filerec->{$sff_file}{file_path};
	
	if ( &extract_fasta_from_sff($sff_file, $file_path, $fasta_file, $qual_file, \*LOG) ) 
	{
	    $filerec->{$sff_file}{sff2fa} = $fasta_file;
	    
	    my $fasta_file_size = -s "$file_path/$fasta_file";
	    my($fasta_file_md5) = (`md5sum '$file_path/$fasta_file'` =~ /^(\S+)/);
	    
	    $filerec->{$fasta_file}  = {
		                         'file_upload'   => $upload_filename,
					 'file_name'     => $fasta_file,
					 'file_base'     => $sff_file,
					 'file_path'     => $file_path,
					 'file_suffix'   => '.fasta',
					 'file_type'     => 'ASCII text',
					 'file_eol'      => $/,
					 'file_format'   => 'fasta',
					 'file_seq_type' => 'DNA',
					 'qual_file'     => $qual_file,
					 'file_md5'      => $fasta_file_md5,
					 'file_size'     => $fasta_file_size,
				     };
	    
	    $filerec->{$sff_file}{fasta_file} = $fasta_file;
	} 
	else 
	{
	    # log error
	    $ts = &timestamp;
	    &print_message("FAIL:\tcould not extract fasta sequence file from sff file '$sff_file'");
	    die "[$ts] could not extract fasta sequence file from sff file '$sff_file'";
	}
	
	$verbose && &print_message("done:\tfasta extraction from sff");
    }

    $verbose && &print_message("start:\tadd error messages");

    # handle bad files
    foreach my $file_name ( keys %$filerec )
    {
	if ( exists $filerec->{$file_name}{error} ) 
	{
	    # ignore files which are already in error state
	    next;
	}

	# files which can not be handled
	if ( $filerec->{$file_name}{file_format} ne 'fasta' and
	     $filerec->{$file_name}{file_format} ne 'fastq' and
	     $filerec->{$file_name}{file_format} ne 'qual'  and
	     $filerec->{$file_name}{file_format} ne 'sff' )
	{
	    $filerec->{$file_name}{error} = &file_format_error_message($filerec->{$file_name}{file_format});
	}

	if ( $filerec->{$file_name}{file_eol} =~ /^ASCII file/ )
	{
	    $filerec->{$file_name}{error} = &file_eol_error_message($filerec->{$file_name}{file_eol});
	}

	if ( $filerec->{$file_name}{file_type} =~ /^unknown file type/ )
	{
	    $filerec->{$file_name}{error} = $filerec->{$file_name}{file_type};
	}

	if ( exists $filerec->{$file_name}{file_seq_type} and $filerec->{$file_name}{file_seq_type} =~ /protein/ )
	{
	    $filerec->{$file_name}{error} = "file seems to contain protein sequences";
	}

    }

    $verbose && &print_message("done:\tadd error messages");
    $verbose && &print_message("start:\tpairing fasta and qual files");

    # pair fasta and .qual files
    my %is_fasta;
    my %is_qual;

    foreach my $file_name ( keys %$filerec )
    {
	if ( $filerec->{$file_name}{file_format} eq 'fasta' ) {
	    $is_fasta{$file_name} = 1;
	}
	elsif ( $filerec->{$file_name}{file_format} eq 'qual' ) {
	    $is_qual{$file_name} = 1;
	}
    }

    foreach my $fasta_file ( keys %is_fasta )
    {
	my $fasta_file_base = $filerec->{$fasta_file}{file_base};
	
	foreach my $qual_file ( keys %is_qual )
	{
	    my $qual_file_base = $filerec->{$qual_file}{file_base};

	    if ( $fasta_file_base eq $qual_file_base )
	    {
		$filerec->{$fasta_file}{qual_file} = $qual_file;
		$filerec->{$qual_file}{fasta_file} = $fasta_file;
	    }
	}
    }

    $verbose && &print_message("done:\tpairing fasta and qual files");

    # compute sequence statistics for fasta files
    foreach my $file_name ( keys %$filerec )
    {
	if ( $filerec->{$file_name}{file_format} eq 'fasta' and $filerec->{$file_name}{file_seq_type} eq 'DNA' )
	{
	    $verbose && &print_message("start:\tcompute fasta file statistics, $file_name");

	    my $file_path = $filerec->{$file_name}{file_path};
	    $filerec->{$file_name}{file_report} = &fasta_report_and_stats($file_name, $file_path, $filerec);

	    $verbose && &print_message("done:\tcompute fasta file statistics, $file_name");
	}
    }
    
    $verbose && &print_message("start:\twrite results to log files");

    # print to LOG file
    foreach my $file_name ( sort keys %$filerec )
    {
	foreach my $key ( sort keys %{ $filerec->{$file_name} } )
	{
	    if ( $key eq 'file_report' )
	    {
		foreach my $file_report_key ( keys %{ $filerec->{$file_name}{file_report} } )
		{
		    print LOG "$file_name\tfile_report\t$file_report_key\t$filerec->{$file_name}{file_report}{$file_report_key}\n";
		}
	    }
	    else
	    {
		print LOG "$file_name\t$key\t$filerec->{$file_name}{$key}\n";
	    }
	}
    }

    my $file_log = "$user_upload_dir/processed_files";

    open(FL, ">$file_log") or die "could not open file '$file_log': $!";
    print FL Dumper($filerec);
    close(FL) or die "could not close file '$file_log': $!";
    
    $ts = &timestamp;
    print LOG "processing completed\t$ts\n";

    flock(LOG, 8) or die "could not unlock file '$log_file': $!";
    close(LOG) or die "could not close file '$log_file': $!";

    chmod 0666, $file_log;

    if ( exists $filerec->{$upload_filename} )
    {
	if ( $filerec->{$upload_filename}{file_format} eq 'fastq' or
	     $filerec->{$upload_filename}{file_format} eq 'sff' )
	{
	    # no more processing required on upload file, e.g. tar files, etc. job creation will proceed on fasta files
	    &mark_status($status_file, $user_dir, $upload_dir, $upload_filename, 'processing_terminated');
	}
    }
    else
    {
	# no more processing required on upload file, e.g. tar files, etc. job creation will proceed on fasta files
	&mark_status($status_file, $user_dir, $upload_dir, $upload_filename, 'processing_terminated');
    }

    foreach my $filename ( sort keys %$filerec )
    {
	if ( $filerec->{$filename}{error} )
	{
	    &mark_status($status_file, $user_dir, $upload_dir, $filename, 'processing_error');
	}
	elsif ( $filerec->{$filename}{file_format} eq 'fasta' and $filerec->{$filename}{file_seq_type} eq 'DNA' )
	{
	    &mark_status($status_file, $user_dir, $upload_dir, $filename, 'processing_completed');
	}
	else
	{
	    # should not reach here
	}
    }

    $verbose && &print_message("done:\twrite results to log files");
}

sub file_format_error_message {
    my($file_format) = @_;

    my $msg = 'could not extract sequence data';

    if ( $file_format eq 'genbank' ) 
    {
	$msg .= ', this may be a genbank file';
    } 
    elsif ( $file_format eq 'malformed' )
    {
	$msg .= ', the file may contain malformed FASTA or malformed fastq';
    }
    elsif ( $file_format eq 'unknown' )
    {
	$msg .= ', unknown format, malformed FASTA or malformed fastq';
    }

    return $msg;
}

sub file_eol_error_message {
    my($file_eol) = @_;

    return "could not extract sequence data, $file_eol";
}

sub read_mid_tags_file {
    my($base_dir, $user_dir, $upload_dir, $upload_filename) = @_;
    
    # read file containing MID tags to be used for demultiplexing
    my @mid_tags;

    my $mid_tags_file = "$base_dir/$user_dir/$upload_dir/$upload_filename.MID_tags";
    open(MID, "<$mid_tags_file") or die "could not open file '$mid_tags_file': $!";

    my $tag;
    while ( defined($tag = <MID>) )
    {
	chomp $tag;
	push @mid_tags, $tag;
    }

    close(MID);

    return \@mid_tags;
}

sub read_processed_log {
    my($base_dir, $user_dir, $upload_dir) = @_;

    # read processed files log which are Dumper formatted                                                                                                                       
    my $file_log = "$base_dir/$user_dir/$upload_dir/processed_files";
    open(FL, "<$file_log") or die "could not open file '$file_log': $!";
    my @lines = <FL>;
    close(FL) or die "could not close file '$file_log': $!";

    my $filerec = eval join('', @lines);
    return $filerec;
}

sub mark_status {
    my($status_file, $user_dir, $upload_dir, $upload_filename, $status)= @_;

    open(STATUS, ">>$status_file") or die "could not open file '$status_file': $!";
    flock(STATUS, 1) or die "could not create shared lock for file '$status_file': $!";

    print STATUS join("\t", $user_dir, $upload_dir, $upload_filename, $status), "\n";

    flock(STATUS, 8) or die "could not unlock file '$status_file': $!";
    close(STATUS) or die "could not close file '$status_file': $!";

    chmod 0666, $status_file;
}

sub fasta_report_and_stats {
    my($file_name, $file_path, $filerec) = @_;

    if ( exists $filerec->{$file_name}{error} )
    {
	return {};
    }

    ### report keys:
    # bp_count, sequence_count, length_max, id_length_max, length_min, id_length_min, file_size,
    # average_length, standard_deviation_length, average_gc_content, standard_deviation_gc_content,
    # average_gc_ratio, standard_deviation_gc_ratio, ambig_char_count, ambig_sequence_count, average_ambig_chars

    my $f_eol = uri_escape( $filerec->{$file_name}{file_eol} );
    # my @stats = `seq_length_stats --fasta_file $file_path/$file_name --eol_code $f_eol --id_stats 2>&1`;
    # take out id checking for now, needs to be moved downstream of job creation
    my @stats = `seq_length_stats --fasta_file '$file_path/$file_name' --eol_code $f_eol 2>&1`;
    chomp @stats;
    
    if ( $stats[0] =~ /^ERROR/i ) {
      my @parts = split(/\t/, $stats[0]);
      if ( @parts == 3 ) {
	$filerec->{$file_name}{error} = $parts[1] . ": " . $parts[2];
	return {};
      }
      else {
	die join("\n", @stats) . "\n";
      }
    }

    my $report = {};
    foreach my $line (@stats) {
      my ($key, $val) = split(/\t/, $line);
      $report->{$key} = $val;
    }
    $report->{file_size} = -s "$file_path/$file_name";

    if ( $report->{sequence_count} == 0 ) {
      $filerec->{$file_name}{error} = "File contains no sequences.";
      return {};
    }
    return $report;
}

sub extract_fasta_from_fastq {
    my($fastq, $fasta, $dir, $file_eol) = @_;

    # call fq2fa which will do the extraction. 
    # this code is from fq_all2std.pl from the Maq package and has been modified to 
    # deal with unusual end-of-line characters
 
    # If necessary, we can pull this and call the Maq script directly

    return &fq2fa($fastq, $fasta, $dir, $file_eol);
}

sub fq2fa {
    my($fastq, $fasta, $dir, $file_eol) = @_;
    # modified code from fq_all2std.pl from Maq package
    
    my $old_eol = $/;
    $/ = $file_eol;

    open(FASTQ, "<$dir/$fastq") or die "could not open fastq file '$dir/$fastq': $!";
    open(FASTA, ">$dir/$fasta") or die "could not open fasta file '$dir/$fasta': $!";

    my $line;

    while ( defined($line = <FASTQ>) ) 
    {
	chomp $line;
        if ( $line =~ /^@(\S+)/ ) 
	{
	    print FASTA ">$1\n";
	    $line = <FASTQ>;
	    chomp $line;
	    print FASTA "$line\n";
	    <FASTQ>; 
	    <FASTQ>;
        }
    }

    close(FASTA) or die "could not close fasta file '$dir/$fasta': $!";
    close(FASTQ) or die "could not close fastq file '$dir/$fastq': $!";

    $/ = $old_eol;

    return 1;
}

sub extract_fasta_from_sff {
    my($sff, $dir, $fasta, $qual, $fh_log) = @_;

    # call sff_extract (http://bioinf.comav.upv.es/sff_extract/)

    eval {
	`sff_extract_0_2_8 -s '$dir/$fasta' -q '$dir/$qual' '$dir/$sff'`;
    };
    
    if ($@)
    {
	print $fh_log "$sff\tError unpacking uploaded sff file '$dir/$sff': $@";
	return 0;
    }

    if ( -s "$dir/$fasta" and -s "$dir/$qual" )
    {
	# files were created by sff_to_fasta
	print $fh_log "$sff\tsff_to_fasta success, created $fasta and $qual\n";
	return 1;
    }
    else
    {
	return 0;
    }
}

sub unpack_file {
    my($file, $dir, $fh_log) = @_;

    my $file_type = &file_type($file, $dir);
    print $fh_log "$file\tfile_type\t$file_type\n";

    # don't create target directory here, may not be needed
    my $target_dir = "$dir/$file.extract";
    my $files = [];

    if ( $file_type eq 'tar archive' or $file_type eq 'POSIX tar archive' ) 
    {
	$files = &untar_file($file, $dir, $target_dir, $fh_log);
    }
    elsif ( $file_type =~ /^gzip compressed data/ ) 
    {
	$files = &gunzip_file($file, $dir, $target_dir, $fh_log);
    }
    elsif ( $file_type =~ /^Zip archive data/ ) 
    {
	$files = &unzip_file($file, $dir, $target_dir, $fh_log);
    }
    else 
    {
	# presumably uncompressed and unarchived file
	# could be non-ASCII -- .rar .doc etc.
	$files = ["$dir/$file"];
    }

    foreach my $file ( @$files )
    {
	chmod 0666, $file;
    }

    return $files;
}

sub untar_file {
    my($file, $dir, $target_dir, $fh_log) = @_;

    mkdir($target_dir);
    chmod 0777, $target_dir;

    my @tar_flags = ("-C", $target_dir, "-v", "-x", "-f", "$dir/$file");
    
    warn "Run tar with: @tar_flags\n";
    
    my @tar_files;

    #
    # Extract and remember filenames.
    #
    # Need to do the 'safe-open' trick here since for now, tarfile names might
    # be hard to escape in the shell.
    #
    my $t1 = time;
    print $fh_log "$file\tuntar\tstarted\n";
    print $fh_log "$file\tuntar_directory\t$target_dir\n";
    
    open(P, "-|", "tar", @tar_flags) or die("cannot run tar: @tar_flags: $!");
    
    while (<P>)
    {
	chomp;
	my $path = "$target_dir/$_";
	warn "Created $path\n";
	push(@tar_files, $path);
    }

    if (! close(P))
    {
	print $fh_log "$file\tuntar failed\t@tar_flags, \$?=$?, \$!=$!\n";
	die("Error closing tar pipe: @tar_flags, \$?=$? \$!=$!");
    }

    my $dt = time - $t1;
    print $fh_log "$file\tuntar_time_in_sec\t$dt\n";
    print $fh_log "$file\tuntar_files_before_filtering\t", join(", ", sort @tar_files), "\n";
    @tar_files = &filter_files(@tar_files);
    print $fh_log "$file\tuntar_files_after_filtering\t", join(", ", sort @tar_files), "\n";
    print $fh_log "$file\tuntar\tcompleted\n";

    return \@tar_files;
}

sub gunzip_file {
    my($file, $dir, $target_dir, $fh_log) = @_;

    # handle both .tgz (multiple files tarred and then gzipped) and .gz (single file gzipped)
    mkdir($target_dir);
    chmod 0777, $target_dir;
 
    # first try untarring:
    my @tar_flags = ("-z", "-C", $target_dir, "-v", "-x", "-f", "$dir/$file");
    
    #warn "Run tar with: @tar_flags";
    
    my(@tar_files, @gunzip_files);

    #
    # Extract and remember filenames.
    #
    # Need to do the 'safe-open' trick here since for now, tarfile names might
    # be hard to escape in the shell.
    # Filename will not be a problem, as the user submitted filename is no longer used, MJD
    #

    my $t1 = time;
    print $fh_log "$file\tfirst trying untar\tstarted\n";
    print $fh_log "$file\tuntar_directory\t$target_dir\n";

    open(P, "-|", "tar", @tar_flags) or die("cannot run tar: @tar_flags: $!");
    
    while (<P>)
    {
	chomp;
	my $path = "$target_dir/$_";
	#warn "Created $path\n";
	push(@tar_files, $path);
    }

    if (! close (P))
    {
	# tar failed, try gunzip
	warn "tar failed, try gunzip for '$file'";
	
	print $fh_log "$file\ttar failed, try gunzip\n";

	my($base, $path, $suffix) = fileparse($file, qr/\.[^.]*$/);
	my $new_file = "$target_dir/$base";

	eval {
	    `zcat '$dir/$file' > $new_file`;
	};
    
	if ($@)
	{
	    print $fh_log "$file\tError gunzipping uploaded file '$dir/$file': $@";

	    my $ts = &timestamp;
	    print "[$ts] Error gunzipping uploaded file '$dir/$$file': $@";
	    return;
	}

	@gunzip_files = ($new_file);
    }

    my $dt = time - $t1;
    print $fh_log "time_taken\t$dt\n";

    if ( @tar_files ) {
	print $fh_log "$file\ttar files before filtering: ", join(", ", sort @tar_files), "\n";
	@tar_files = &filter_files(@tar_files);
	print $fh_log "$file\ttar files after filtering: ", join(", ", sort @tar_files), "\n";
	print $fh_log "$file\tuntar\tcompleted\n";
	
	return \@tar_files;
    }
    elsif ( @gunzip_files ) {
	print $fh_log "$file\tgunzip\tcompleted\n";
	return \@gunzip_files;
    }
    else {
	die "could not gunzip file: $file";
    }
}

sub unzip_file {
    my($file, $dir, $target_dir, $fh_log) = @_;
    
    mkdir($target_dir);
    chmod 0777, $target_dir;

    my @unzip_flags = ("-o", "$dir/$file", "-d", $target_dir);
    
    warn "Run unzip with @unzip_flags\n";
    
    my @zip_files;

    #
    # Extract and remember filenames.
    #
    # Need to do the 'safe-open' trick here since for now, tarfile names might
    # be hard to escape in the shell.
    #

    print $fh_log "$file\tunzip\tstarted\n";
    print $fh_log "$file\tunzip_directory\t$target_dir\n";
    my $t1 = time;

    open(P, "-|", "unzip", @unzip_flags) or die("cannot run unzip @unzip_flags: $!");
    
    while (<P>)
    {
	chomp;
	if (/^\s*[^:]+:\s+(.*?)\s*$/)
	{
	    my $path = $1;

	    if ( $path ne $file )
	    {
		warn "Created $path\n";
		push(@zip_files, $path);
	    }
	}
    }

    if (!close(P))
    {
	print $fh_log "$file\tError closing unzip pipe: \$?=$? \$!=$!";
	die("Error closing unzip pipe: \$?=$? \$!=$!");
    }

    my $dt = time - $t1;
    print $fh_log "$file\tunzip_time_in_sec\t$dt\n";
    print $fh_log "$file\tunzip_files_before_filtering\t", join(", ", sort @zip_files), "\n";
    @zip_files = &filter_files(@zip_files);
    @zip_files = grep {$_ ne "$dir/$file"} @zip_files;
    print $fh_log "$file\tunzip_files_after_filtering\t", join(", ", sort @zip_files), "\n";

    return \@zip_files;
}

sub filter_files {
    my(@files) = @_;

    # drop unnecessary files from list produced during unarchiving process
    @files = grep {! /\._/} @files;   # drop ._ files from Mac OS X
    @files = grep {! -d} @files;      # drop directories
    @files = grep {-s} @files;        # drop zero-size files
    
    return @files;
}

sub file_type {
    my($file, $dir) = @_;

    #
    # Need to do the 'safe-open' trick here since for now, file names might
    # be hard to escape in the shell.
    #
    
    open(P, "-|", "file", "-b", "$dir/$file") or die("cannot run file command on file '$dir/$file': $!");
    my $file_type = <P>;
    close(P);

    chomp $file_type;

    if ( $file_type =~ m/\S/ ) 
    {
	$file_type =~ s/^\s+//;   #...trim leading whitespace
	$file_type =~ s/\s+$//;   #...trim trailing whitespace
    }
    else
    {
	# file does not work for fastq -- craps out for lines beginning with '@' on mg-rast machine!
	# check first 4 lines for fastq like format
	my @lines = `cat -A '$dir/$file' | head -n4`;
	chomp @lines;

	if ( $lines[0] =~ /^\@/  and $lines[0] =~ /\$$/ and
	     $lines[1] =~ /\$$/ and
	     $lines[2] =~ /^\+/  and $lines[2] =~ /\$$/ and
	     $lines[3] =~ /\$$/ )
	{
	    $file_type = 'ASCII text';
	}
	else
	{
	    $file_type = 'unknown file type, check end-of-line characters and (if fastq) fastq formatting';
	}
    }

    return $file_type;
}

sub file_seq_type {
    my($file_name, $file_path, $file_eol) = @_;

    my $max_chars = 10000;

    # read first $max_chars characters of sequence data to check for protein sequences
    # this does NOT do validation of fasta format

    my $old_eol = $/;
    $/ = $file_eol;

    my $seq = '';
    my $line;
    open(TMP, "<$file_path/$file_name") or die "could not open file '$file_path/$file_name': $!";
    while ( defined($line = <TMP>) )
    {
	chomp $line;
	if ( $line =~ /^\s*$/ or $line =~ /^>/ ) 
	{
	    next;
	}
	else
	{
	    $seq .= $line;
	}

	last if (length($seq) >= $max_chars);
    }
    close(TMP);

    $/ = $old_eol;

    $seq =~ tr/A-Z/a-z/;

    my %char_count;
    foreach my $char ( split('', $seq) )
    {
	$char_count{$char}++;
    }

    $char_count{a} ||= 0;
    $char_count{c} ||= 0;
    $char_count{g} ||= 0;
    $char_count{t} ||= 0;
    $char_count{n} ||= 0;
    $char_count{x} ||= 0;
    $char_count{'-'} ||= 0;
    
    # find fraction of a,c,g,t characters from total, not counting '-', 'N', 'X'
    my $bp_char = $char_count{a} + $char_count{c} + $char_count{g} + $char_count{t};
    my $n_char  = length($seq) - $char_count{n} - $char_count{x} - $char_count{'-'};
    my $fraction = $bp_char/$n_char;

    if ( $fraction <= 0.6 ) {
	return "possibly protein sequences";
    }
    else {
	return 'DNA';
    }
}

=pod

=item * B<file_eol> ()

Use $file_type to determine EOL character

http://en.wikipedia.org/wiki/Newline

LF: Line Feed
CR: Carriage Return

LF:    Multics, Unix and Unix-like systems (GNU/Linux, AIX, Xenix, Mac OS X, FreeBSD, etc.), BeOS, Amiga, RISC OS, and others
CR+LF: DEC RT-11 and most other early non-Unix, non-IBM OSes, CP/M, MP/M, DOS (MS-DOS, PC-DOS, etc.), OS/2, Microsoft Windows, Symbian OS, Palm OS
CR:    Commodore 8-bit machines, TRS-80, Apple II family, Mac OS up to version 9 and OS-9
RS:    QNX pre-POSIX implementation.

sed -e 's/$/\r/' inputfile > outputfile                # UNIX to DOS  (adding CRs)
sed -e 's/\r$//' inputfile > outputfile                # DOS  to UNIX (removing CRs)
perl -pe 's/\r\n|\n|\r/\r\n/g' inputfile > outputfile  # Convert to DOS
perl -pe 's/\r\n|\n|\r/\n/g'   inputfile > outputfile  # Convert to UNIX
perl -pe 's/\r\n|\n|\r/\r/g'   inputfile > outputfile  # Convert to old Mac

use cat -A filename or cat -e filename to visualize EOL characters

=cut

sub file_eol {
    my($file_type) = @_;

    my $file_eol;

    if ( $file_type =~ /ASCII/ )
    {
	# ignore some useless informationa and stuff that gets in when the file command guesses wrong
	$file_type =~ s/, with very long lines//;
	$file_type =~ s/C\+\+ program //;
	$file_type =~ s/Java program //;
	$file_type =~ s/English //;

	if ( $file_type eq 'ASCII text' )
	{
	    $file_eol = $/;
	}
	elsif ( $file_type eq 'ASCII text, with CR line terminators' )
	{
	    $file_eol = "\cM";
	}
	elsif ( $file_type eq 'ASCII text, with CRLF line terminators' )
	{
	    $file_eol = "\cM\cJ";
	}
	elsif ( $file_type eq 'ASCII text, with CR, LF line terminators' )
	{
	    $file_eol = "ASCII file has mixed (CR, LF) line terminators";
	}
	elsif ( $file_type eq 'ASCII text, with CRLF, LF line terminators' ) 
	{
	    $file_eol = "ASCII file has mixed (CRLF, LF) line terminators";
	}
	elsif ( $file_type eq 'ASCII.*text, with CRLF, CR line terminators' ) 
	{
	    $file_eol = "ASCII file has mixed (CRLF, CR) line terminators";
	}
	elsif ( $file_type eq 'ASCII text, with no line terminators' ) 
	{
	    $file_eol = "ASCII file has no line terminators";
	}
	else 
	{
	    # none of the above? use default and see what happens
	    $file_eol = $/;
	}
    }
    else
    {
	# non-ASCII?
	$file_eol = $/;
    }
	
    return $file_eol;
}

sub file_format {
    my($file_name, $file_path, $file_type, $file_suffix, $file_eol) = @_;

    if ( $file_suffix eq '.qual' ) 
    {
	return 'qual';
    }

    if ( $file_type eq 'data' and $file_suffix eq '.sff' ) 
    {
	return 'sff';
    }

    # identify fasta or fastq
    
    my $file_format;
    if ( $file_type =~ /^ASCII/ )
    {
	my @chars;
	my $old_eol = $/;
	my $line;
	my $i;
	open(TMP, "<$file_path/$file_name") or die "could not open file '$file_path/$file_name': $!";
	
	while ( defined($line = <TMP>) and chomp $line and $line =~ /^\s*$/ )
	{
	    # ignore blank lines at beginning of file
	}

	close(TMP) or die "could not close file '$file_path/$file_name': $!";
	$/ = $old_eol;

	if ( $line =~ /^LOCUS/ ) 
	{
	    return 'genbank';
	}
	elsif ( $line =~ /^>/ ) 
	{
	    return 'fasta';
	}
	elsif ( $line =~ /^@/ )
	{
	    return 'fastq';
	}
	else
	{
	    return 'malformed';
	}
    }
    else
    {
	return 'unknown';
    }
}

sub upload_status {
    my($status_file) = @_;
    
    my $line;
    my %status;
    my %upload_status = ();

    open(STATUS, "<$status_file") or die "could not open file '$status_file': $!";
    flock(STATUS, 1) or die "could not create shared lock for file '$status_file': $!";

    while ( defined($line = <STATUS>) )
    {
	# ignore lines beginning with '#'
	next if ($line =~ /^\#/);

	chomp $line;
	my($user_dir, $upload_dir, $upload_filename, $upload_status) = split("\t", $line);
	
	# this will keep only the last status for the upload
	$status{$user_dir}{$upload_dir}{$upload_filename} = $upload_status;
    }

    flock(STATUS, 8) or die "could not unlock file '$status_file': $!";
    close(STATUS) or die "could not close file '$status_file': $!";

    foreach my $user_dir ( keys %status )
    {
	foreach my $upload_dir ( keys %{ $status{$user_dir} } )
	{
	    foreach my $upload_filename ( keys %{ $status{$user_dir}{$upload_dir} } )
	    {
		if ( $status{$user_dir}{$upload_dir}{$upload_filename} eq 'upload_completed' )
		{
		    # this upload file does not have status 'processing_completed'
		    push @{ $upload_status{upload_completed} }, [$user_dir, $upload_dir, $upload_filename];
		}
		elsif ( $status{$user_dir}{$upload_dir}{$upload_filename} eq 'demultiplex' )
		{
		    # this upload file does not have status 'processing_completed'
		    push @{ $upload_status{demultiplex} }, [$user_dir, $upload_dir, $upload_filename];
		}
		else
		{
		    # ignore all others
		}
	    }
	}
    }

    return \%upload_status;
}

sub split_fasta_by_mid_tag {
    my($fasta_file, $file_path, $file_eol, $target_dir, $mid_tags) = @_;

    # split a fasta file by the multiplex ID (MID) tag
    my($file_base, undef, undef) = fileparse($fasta_file, qr/\.[^.]*$/);

    # open file for each MID tag and one for unmatched sequences and store the filehandles in a hash
    my %filehandle;
    foreach my $file_ext ( @$mid_tags, 'no_MID_tag' )
    {
	my $file = $target_dir . '/' . $file_base . '_' . $file_ext . '.fasta';
	$filehandle{$file_ext} = &newopen($file);
    }

    my $rec;
    my $old_eol = $/;
    $/ = $file_eol . '>';

    open(FASTA, "<$file_path/$fasta_file") or die "could not open file '$file_path/$fasta_file': $!";
    while ( defined($rec = <FASTA>) )
    {
	chomp $rec;
	my($id_line, @lines) = split($file_eol, $rec);
	
	$id_line =~ s/^>*//;
	
	my $seq = join('', @lines);
	
	my $file_ext = '';
	
	# search for a MID tag
	foreach my $mid_tag ( @$mid_tags )
	{
	    if ( $seq =~ /^$mid_tag/i )
	    {
		$file_ext = $mid_tag;
		
		# trim off a segment same length as the MID tag
		my $trimmed = substr($seq, length($mid_tag));
		$seq = $trimmed;
		last;
	    }
	}
	
	if ( ! $file_ext ) 
	{
	    $file_ext = 'no_MID_tag';
	}
	
	my $fh = $filehandle{$file_ext};
	
	my $formatted_seq = &fasta_formatted_sequence($seq, 60);
	
	print $fh ">$id_line\n$formatted_seq";
    }
    close(FASTA) or die "c";

    $/ = $old_eol;

    my @files = ();
    # close all filehandles
    foreach my $file_ext ( @$mid_tags, 'no_MID_tag' )
    {
	my $file = $target_dir . '/' . $file_base . '_' . $file_ext . '.fasta';
	my $fh   = $filehandle{$file_ext};
	close($fh) or die "could not close file '$file': $!";
	chmod 0666, $file;
	push @files, $file;
    }

    return \@files;
}

sub fasta_formatted_sequence {
    my($seq, $line_length) = @_;
    my($seg, @seq_lines);

    $line_length ||= 60;
    my $offset     = 0;
    my $seq_ln     = length($seq);

    while ( $offset < ($seq_ln - 1) and defined($seg = substr($seq, $offset, $line_length)) )
    {
        push(@seq_lines, $seg);
        $offset += $line_length;
    }

    my $fasta_sequence = join("\n", @seq_lines) . "\n";
    return $fasta_sequence;
}

sub newopen {
    my($file) = @_;
    local *FH;  # not my!

    open (FH, ">$file") || die "could not open file '$file': $!";
    return *FH;
}

sub timestamp {
    
    my($sec, $min, $hour, $day, $month, $year) = localtime;

    $month += 1;
    $year  += 1900;

    $sec   = &pad($sec);
    $min   = &pad($min);
    $hour  = &pad($hour);
    $day   = &pad($day);
    $month = &pad($month);

    return join(':', $year, $month, $day, $hour, $min, $sec);
}

sub pad {
    my($str) = @_;

    # requires $str to be a string of length 1 or 2, left-pad with a zero if length == 1

    return (length($str) == 2)? $str : '0' . $str;
}

sub print_message {
    my($msg) = @_;

    my $ts = &timestamp;
    print "[$ts] $msg\n";
}


