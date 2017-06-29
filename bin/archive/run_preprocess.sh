#!/bin/sh

user=`whoami`
. ~mgrastprod/.zshenv

# --user_dir <user_dir> --upload_dir <upload_dir> --upload_filename <upload_filename> [ --demultiplex --partitioned ]
# options
user_dir=""
upload_dir=""
upload_filename=""
demultiplex=0
partitioned=0
help=0

if [ ${user} != 'mgrastprod' ]; then echo '[error] must be user mgrastrprod'; exit 1; fi

source ~mgrastprod/.zshenv 

# Please note the following section is magic. Change at your own risk.
if ! opts=$(getopt -u -o h -l user_dir:,upload_dir:,upload_filename:,demultiplex,partitioned,help -- "$@"); then exit 1; fi
set -- $opts
while [ $# -gt 0 ]
do
    case "$1" in
		--user_dir) user_dir=$2; shift 2 ;;
		--upload_dir) upload_dir=$2; shift 2 ;;
		--upload_filename) upload_filename=$2; shift 2 ;;
		--demultiplex) demultiplex=1; shift ;;
		--partitioned) partitioned=1; shift ;;
		-h|--help) help=1; shift ;;
		--) shift; break;;
		-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
		*) break;;
    esac
done

if [ $help -eq 1 ]; then 
	echo "Usage: "`basename $0`" --user_dir <user_dir> --upload_dir <upload_dir> --upload_filename <upload_filename> [ --demultiplex --partitioned ]";
	exit 0;
fi

if [ -z "$user_dir" ] || [ -z "$upload_dir" ] || [ -z "$upload_filename" ]; then
	echo "Usage: "`basename $0`" --user_dir <user_dir> --upload_dir <upload_dir> --upload_filename <upload_filename> [ --demultiplex --partitioned ]";
	echo "ERROR: missing one or more options"
	exit 0;
fi

run_preprocess.pl --user_dir $user_dir --upload_dir $upload_dir --upload_filename $upload_filename --demultiplex $demultiplex --partitioned $partitioned
