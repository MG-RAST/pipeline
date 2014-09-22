# MG-RAST dockerfiles

FROM	ubuntu:14.04
MAINTAINER The MG-RAST team

RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y vim ssh git build-essential python-dev python-pip libpq-dev perl-modules libcache-memcached-perl libcwd-guard-perl libdbi-perl libdbd-mysql-perl libdbd-pg-perl libmongodb-perl libdata-dump-streamer-perl libdatetime-perl libdigest-md5-perl libdigest-md5-file-perl libfile-slurp-perl libfilehandle-fmode-perl libjson-perl libstring-random-perl libtemplate-perl libwww-perl libgetopt-long-descriptive-perl liburi-encode-perl libunicode-escape-perl liblist-allutils-perl libposix-strptime-perl
RUN for i in install biopython psycopg2 gspread openpyxl numpy; do pip install $i; done
RUN cd /root ; mkdir bin ; git clone https://github.com/MG-RAST/pipeline