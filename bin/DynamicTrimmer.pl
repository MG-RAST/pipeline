#!/usr/bin/env perl

# Program: DynamicTrim v.1.4a
# Trims each sequence of a FASTQ file individually to the longest contiguous segment 
# in which the quality score of each base is superior to an input quality cutoff
# Daniel Peterson and Murray Cox
# Massey University Palmerston North, New Zealand
# Email contact <m.p.cox@massey.ac.nz>
# December 2010

# Version 1.2: 48% speed improvement using substr()
# Change suggested by Douglas Scofield
# Ecology & Evolutionary Biology, University of California Los Angeles
# Email contact <douglasgscofield@gmail.com>

# Version 1.3: Automatic FASTQ format detection

# Version 1.4: Fixed automatic FASTQ format detection bug (user-defined formats)
#              Added BWA-style read trimming

# Version 1.4a:  March 7, 2011   W. Trimble @ Argonne National Laboratory
#              Modifications to make trimming more broadly applicable for 
#              use as a preprocessor in MG-RAST.  Spefcifically:
#              Added a third trimming algorithm, 454 trimming, that trims only 
#              from the beginning and does not truncate until maxtolerable 
#              low-quality bases are observed in a given read. 

#              There are now three trimming algorithms, 
#              (default) trim to longest stretch of bases with no low-quality
#              BWA algorithm -
#              454 algorithm trim until at most maxtolerable low-quality bases are seen 


# Released under GNU General Public License version 3

use strict;
use warnings;
use Getopt::Long;

my $usage = "
$0 input_files [-p|probcutoff 0.05] [-h|phredcutoff 13] [-b|bwa] [-sanger -solexa -illumina] [-454]\n
-p|probcutoff	probability value (between 0 and 1) at which base-calling error is considered too high (default; p = 0.05) *or*
-h|phredcutoff  Phred score (between 0 and 40) at which base-calling error is considered too high (default 13)
                use SolexaQA trimming algorithm (default)
-b|bwa          use BWA trimming algorithm
-454            use 454 trimming algorithm 
-sanger         Sanger format (bypasses automatic format detection)
-solexa         Solexa format (bypasses automatic format detection)
-illumina       Illumina format (bypasses automatic format detection)
-n|maxtolerable number of low-quality bases to accept (option for 454 trimming algorithm, default 5)
-l|length_min   minimum sequence length to not be rejected (default is 50)

Function: takes fastq input_files and performs trimming of the sequences to remove low-quality regions.
Does not discard any sequences, though makes some of them zero-length.
Creates output file called input_file.trimmed.fastq and input_file.rejected.fastq.  Refuses to overwrite output file.
\n";

# if not input files provided, quit and print usage information
if( !$ARGV[0] ){ die "$usage"; }

# create cutoff variables
my $prob_cutoff;
my $phrd_cutoff;
my $max_tolerate = 5;
my $ascii_cutoff;
my $length_min = 50;

my $automatic_detection_lines = 1000;
my $sanger;
my $solexa;
my $illumina;
my $format;
my $user_defined;

my $bwa;
my $roche;

# Get user input
GetOptions(
	"p|probcutoff=f"  => \$prob_cutoff,
	"h|phredcutoff=f" => \$phrd_cutoff,
	"n|max_tolerate=i"=> \$max_tolerate,
	"l|length_min=i"  => \$length_min,
	"b|bwa"           => \$bwa,
	"sanger"          => \$sanger,
	"solexa"          => \$solexa,
	"illumina"        => \$illumina,
	"454"             => \$roche
);
# print STDERR "Maxtolerate = $max_tolerate\n"; WT
# get user format (if supplied)
if( ($sanger && $solexa) || ($sanger && $illumina) || ($solexa && $illumina) ){
  die "error: please select only one of -sanger, -solexa or -illumina\n";
}

if( $sanger || $solexa || $illumina ){
  $user_defined = 1;
}

if( $sanger ){
  $format = "sanger";
}elsif( $solexa ){
  $format = "solexa";
}elsif( $illumina ){
  $format = "illumina";
}

if( $roche ){
  #	$format = "sanger";
}

if ($length_min < 0) {
  $length_min = 0;
}

# get files
my @files = @ARGV;

# check for presence of at least one input file
if( !$files[0] ){ die "$usage"; }

# check for correct cutoff input
if( !defined( $prob_cutoff ) && !defined( $phrd_cutoff ) ){
  $prob_cutoff = 0.05;
  print STDOUT "Info: Using default quality cutoff of P = $prob_cutoff (change with -p or -h flag)\n";
  
}elsif( defined( $prob_cutoff ) && defined( $phrd_cutoff ) ){
  die "Error: Please enter either a probability or a Phred quality cutoff value, not both";
  
}elsif( defined( $prob_cutoff ) && ( $prob_cutoff < 0 || $prob_cutoff > 1 ) ){
  die "Error: P quality cutoff must be between 0 and 1";
  
}elsif( defined( $phrd_cutoff ) && $phrd_cutoff < 0 ){
  die "Error: Phred quality cutoff must be greater than or equal to 0";
}

# determine bwa trimming threshold
my $threshold = 0;
if( $bwa ){
  
  $threshold = &p_to_Q( $prob_cutoff );
}

# temp
#die &print_lookup_table;

foreach my $input_file ( @files ){
  
  # open input file for reading
  open( INPUT, "<$input_file" ) or die "Error: Failure opening $input_file for reading: $!\n";
  
  # just get filename, not full path (as returned by @ARGV)
  #my @filepath = split( /\//, $input_file );
  #my $filename = $filepath[$#filepath];
  
  ## $filename includes path, otherwise can not find output file.
  my $filename = $input_file;
  
  # determine format
  if( !$user_defined ){
    $format = "";
  }
  if( !$format ){
    
    $format = &get_format(*INPUT, $automatic_detection_lines);
    if( !$format ){
      die "Error: File format cannot be determined\n";
    }
  }
  
  # print format information
  if( $roche ){
    print STDOUT "454 trimming option selected\n";
  }
  if( $format eq "sanger" ){
    if( $user_defined ){
      print STDOUT "User defined format: Sanger FASTQ format\n";
    }else{
      print STDOUT "Automatic format detection: Sanger FASTQ format\n";
    }
  }elsif( $format eq "solexa" ){
    if( $user_defined ){
      print STDOUT "User defined format: Solexa FASTQ format, Illumina pipeline 1.2 or less\n";
    }else{ 
      print STDOUT "Automatic format detection: Solexa FASTQ format, Illumina pipeline 1.2 or less\n";
    }
  }elsif( $format eq "illumina" ){
    if( $user_defined ){
      print STDOUT "User defined format: Illumina FASTQ format, Illumina pipeline 1.3+\n";
    }else{
      print STDOUT "Automatic format detection: Illumina FASTQ format, Illumina pipeline 1.3+\n";
    }
  }
  
  # convert input probability or Phred quality cutoff values to the equivalent ascii character
  if( defined( $phrd_cutoff ) ){
    $ascii_cutoff = &Q_to_q( $phrd_cutoff );
  }else{
    $ascii_cutoff = &Q_to_q( &p_to_Q( $prob_cutoff ) );
  }
  
  #print "format is ", $format, "\n";
  #print "prob cutoff is ", $prob_cutoff, "\n";
  #print "p to Q is ", &p_to_Q( $prob_cutoff ), "\n";
  #print "ascii cutoff is ", $ascii_cutoff, "\n";
  
  # create and open output file
  my $output_trim_file   = $filename . ".trimmed.fastq";
  my $output_reject_file = $filename . ".rejected.fastq";
  
  if ( (-e $output_trim_file) || (-e $output_reject_file) ) {
    die "Error: Output file $output_trim_file or $output_reject_file already exists: $!\n";
  }    
  open(OUT_TRM, ">$output_trim_file") or die "Error: Failure opening $output_trim_file for writing: $!\n";
  open(OUT_REJ, ">$output_reject_file") or die "Error: Failure opening $output_reject_file for writing: $!\n";
  
  my @segment_hist;
  my $segment_sum   = 0;
  my $segment_count = 0;
  
  my $seq_count = 0;
  
  # step through input
  while( <INPUT> ){
    
    # first line of each group has the sequence ID
    my $ID1 = $_;
    
    # check that sequence ID has FASTQ '@' indicator
    if( substr( $ID1, 0 , 1) ne "@" ){
      die "Error: Input file not in correct FASTQ format at seq ID $ID1\n";
    }
    
    # second line of the group has the sequence itself
    chomp( my $seq_string = <INPUT> );
    my $orig_seq = $seq_string;
    
    # third line of the group has the sequence ID again
    my $ID2 = <INPUT>;
    
    # check that third line has FASTQ '+' indicator
    if( substr( $ID2, 0 , 1) ne "+" ){
      die "Error: Input file not in correct FASTQ format at qual ID $ID2\n";
    }
    
    # fourth line of the group has the quality scores
    chomp( my $quality_string = <INPUT> );
    my $orig_quality = $quality_string;
    
    # store the original length of the read
    my $original_length  = length $seq_string;
    
    # initialize variables used in segment analysis
    my $cutoff_hit       =  0;
    my $best_start_index =  0;
    my $best_length      =  0;
    my $current_start    =  0;
    my $bad_first        =  0;
    #print $ID1;	 # WTDEBUG
    # perform trimming
    if( $bwa ){
      
      my @qual = split(//, $quality_string );
      
      # transform quality values from ASCII into Solexa format
      for( my $i = 0; $i < scalar @qual; $i++ ){
	$qual[$i] = &q_to_Q($qual[$i]);
      }
      
      $best_length = &bwa_trim( $threshold, \@qual );
      
      if( $qual[0] < $threshold ){
	$bad_first = 1;
      }
      
    }elsif($roche)
      {  # START new 454 trimming algorithm ===========================================
	$cutoff_hit=0;	
	# loop through each position in the read
	for( my $i = 0; $i < $original_length; $i++ ){
	  # if the quality score at this position is worse than the cutoff
	  if( substr($quality_string, $i, 1) le $ascii_cutoff ){
	    #print "$i: badscore $cutoff_hit\n";
	    # increment bad-basepair counter
	    $cutoff_hit++;   
	    if($cutoff_hit == $max_tolerate+1) {
	      #print STDERR "$i: cutoff $cutoff_hit = $max_tolerate+1 \n";
	      #  we've reached the maximum, time to truncate
	      $best_length      = $i - $current_start ; 
	      $best_start_index = $current_start;
	      $i=$original_length;  #stop looping through read
	    }	
	  }
	}
	# if quality threshold was never exceeded, set the marker for the end of the read.
	if( $cutoff_hit< $max_tolerate+1 ){
	  $best_length = $original_length;
	}
      }else # end new 454 trimming algorithm ======================================
	{   # orignial SolexaQA filtering algorithm 
	  # loop through each position in the read
	  for( my $i = 0; $i < $original_length; $i++ ){
	    
	    # if the quality score at this position is worse than the cutoff
	    if( substr($quality_string, $i, 1) le $ascii_cutoff ){
	      
	      $cutoff_hit = 1;
	      
	      # determine length of good segment that just ended
	      my $current_segment_length = $i - $current_start;
	      
	      # if this segment is the longest so far
	      if( $current_segment_length > $best_length ){
		
		# store this segment as current best
		$best_length      = $current_segment_length;
		$best_start_index = $current_start;
	      }
	      
	      # reset current start
	      $current_start = $i + 1;
	      
	    }elsif( $i == $original_length - 1){
	      
	      # determine length of good segment that just ended
	      my $current_segment_lengt = ($i + 1) - $current_start;
	      
	      # if this segment is the longest so far
	      if( $current_segment_lengt > $best_length ){
		
		# store this segment as current best
		$best_length = $current_segment_lengt;
		$best_start_index = $current_start;
	      }
	    }
	  }
	  
	  # if quality cutoff is never exceeded, set the marker for the end of the good segment
	  # to the end of the read
	  if( !$cutoff_hit ){
	    $best_length = $original_length;
	  }
	}
    
    
    
    if( !defined($segment_hist[ $best_length ] ) ){
      $segment_hist[ $best_length ] = 0;
    }
    
    # increment variables that store segment statistics
    $segment_hist[ $best_length ]++;
    $segment_sum += $best_length;
    $segment_count++;
    
    # remove all bases not part of the best segment
    if( $bwa ){
      
      if( $best_length <= 1 && $bad_first ) {
	$seq_string = "N";
	$quality_string = "B";
      }else{
	$seq_string = substr($seq_string, 0, $best_length);
	$quality_string = substr($quality_string, 0, $best_length);
      }
    }else{
      if ($best_length <= 0) {
	$seq_string = "N";
	$quality_string = "B";
      } else {
	$seq_string = substr($seq_string, $best_start_index, $best_length);
	$quality_string = substr($quality_string, $best_start_index, $best_length);
      }
    }
    
    # print ID lines, trimmed sequence, and trimmed quality scores to output file
    if (length($seq_string) >= $length_min) {
      print OUT_TRM $ID1, $seq_string, "\n", $ID2, $quality_string, "\n";
    } else {
      print OUT_REJ $ID1, $orig_seq, "\n", $ID2, $orig_quality, "\n";
    }
  }
  
  # calculate mean segment length
  my $segment_mean = sprintf( "%.1f", $segment_sum / $segment_count );
  
  # set index at halfway through segment counts 
  my $halfway_index = $segment_count / 2;
  
  # set variables needed to find median segment length
  my $current_sum   = 0;
  my $current_index = 0;
  my $median_index1;
  my $median_index2;
  
  # while median_index1 and median_index2 are not defined
  while( !defined( $median_index1 ) || !defined( $median_index2 ) ){
    
    # add segment count to current sum for each segment length from array
    if( defined( $segment_hist[ $current_index ] ) ){
      
      $current_sum += $segment_hist[ $current_index ];
    }
    
    # if current sum of segment counts has surpassed halfway index
    if( $current_sum > $halfway_index ){
      
      # if median_index1 has not been defined, store current segment length
      if( !defined( $median_index1 ) ){
	$median_index1 = $current_index;
      }
      
      # if median_index2 has not been defined, store current segment length
      if( !defined( $median_index2 ) ){
	$median_index2 = $current_index;
      }
      
      # else if current sum of segment counts is exactly equal to the halfway index
    }elsif( $current_sum == $halfway_index	&& !defined( $median_index1 ) ){
      
      # store current segment length as median_index1
      $median_index1 = $current_index;
    }
    
    # loop through all possible segment lengths
    $current_index++;
  }
  
  $current_index--;
  
  my $segment_median;
  
  # if number of segments is odd, store index2 as median segment length
  if( $segment_count % 2 == 1){
    $segment_median = $median_index1;
    
    # if number of segments is even, store average of index1 and index2 as median segment length
  }else{
    $segment_median = sprintf( "%.0f", ( ( $median_index1 + $median_index2 ) / 2 ) );
  }
  
  # print mean and median segment length
  #print STDOUT "Info: $output_trim_file: mean segment length = $segment_mean, median segment length = $segment_median\n";
  
  # close input and output files
  close INPUT or die "Error: Cannot close $input_file: $!";
  close OUT_TRM or die "Error: Cannot close $output_trim_file; $!";
  close OUT_REJ or die "Error: Cannot close $output_reject_file; $!";
}

# terminate
exit 0 or die "Error: program $0 ended abnormally: $!\n";

# ----------------------------------------------------

# Change ASCII character to Phred/Solexa quality score
sub q_to_Q($){

        my $q = shift;
        if( $format eq "sanger" ){
        	return ord($q) - 33;
        }else{
        	return ord($q) - 64;
        }
}

# Change Phred/Solexa quality score to ASCII character
sub Q_to_q($){

        my $Q = shift;
        if( $format eq "sanger" ){
        	return chr($Q + 33);
        }else{
        	return chr($Q + 64);
        }
}

# Change Phred/Solexa quality score to probability
sub Q_to_p($){

	my $Q = shift;

	if( $format eq "solexa" ){
		return (10**(-$Q/10)) / ((10**(-$Q/10))+1);
	}else{
		return (10**(-$Q/10));
	}
}

# Change probability to Phred/Solexa quality score
sub p_to_Q($){

	my $p = shift;
		
		if( $format && $format eq "solexa" ){
			return -10 * &log10($p/(1-$p));
        }else{
			return -10 * &log10($p);
        }
}

# log10 function
sub log10($){

	my $number = shift;
	return log($number)/log(10);
}

# print summary of Q, q and p values
sub print_lookup_table(){
	
	print STDOUT "Char\tQPhred\tProb\n";
	for( my $i = -5; $i <= 40; $i++ ){
		
		my $q = &Q_to_q($i);
		my $p = &Q_to_p($i);
		
		print STDOUT $q, "\t";
		print STDOUT $i, "\t";
		print STDOUT sprintf("%.8f", $p), "\n";
	}
}

# automatic format detection
sub get_format(*$){
	
	# set function variables
	local *FILEHANDLE = shift;
	my $number_of_sequences = shift;
	my $format = "";
	
	# set regular expressions
	my $sanger_regexp = qr/[!"#$%&'()*+,-.\/0123456789:]/;
	my $solexa_regexp = qr/[\;<=>\?]/;
	my $solill_regexp = qr/[JKLMNOPQRSTUVWXYZ\[\]\^\_\`abcdefgh]/;
	my $all_regexp = qr/[\@ABCDEFGHI]/;
	
	# set counters
	my $sanger_counter = 0;
	my $solexa_counter = 0;
	my $solill_counter = 0;
	
	# go to file start
	seek(FILEHANDLE, 0, 0);
	
	# step through quality scores
	for( my $i = 0; $i < $number_of_sequences; $i++ ){
		
		# test for end of file
		last if eof(FILEHANDLE);
		
		# retrieve qualities
		<FILEHANDLE>;
		<FILEHANDLE>;
		<FILEHANDLE>;
		my $qualities = <FILEHANDLE>;
		chomp($qualities);
		
		# check qualities
		if( $qualities =~ m/$sanger_regexp/ ){
			$sanger_counter = 1;
			last;
		}
		if( $qualities =~ m/$solexa_regexp/ ){
			$solexa_counter = 1;
		}
		if( $qualities =~ m/$solill_regexp/ ){
			$solill_counter = 1;
		}
	}
	
	# determine format
	if( $sanger_counter ){
		$format = "sanger";
	}elsif( !$sanger_counter && $solexa_counter ){
		$format = "solexa";
	}elsif( !$sanger_counter && !$solexa_counter && $solill_counter ){
		$format = "illumina";
	}else{
	        $format = "sanger";
	}
	
	# go to file start
	seek(FILEHANDLE, 0, 0);
	
	# return file format
	return( $format );
}

# trim sequences using the BWA algorithm
sub bwa_trim($$){
	
	my $threshold = shift;
	my $array_ref = shift;
	
	my @array  = @{$array_ref};
	my $length = scalar @array;
	
	# only calculate if quality fails near end
	if( $array[$#array] >= $threshold ){
		return $length;
	}
	
	# run bwa equation
	my @arg;
	for( my $i = 0; $i < $length - 1; $i++ ){
		
		my $x = $i + 1;
		for( my $j = $x; $j < $length; $j++ ){	
			$arg[$x] += $threshold - $array[$j];
		}
	}
	
	# find number of 5' bases to retain
	my $index = 0;
	my $maxval = 0;
	for ( 1 .. $#arg ){
		if ( $maxval < $arg[$_] ){
        	$index = $_;
        	$maxval = $arg[$_];
    	}
	}
	
	# number of bases to retain
	return $index;
}
