# MG-RAST dockerfiles

FROM	ubuntu:15.10
MAINTAINER The MG-RAST team

RUN apt-get update && apt-get install -y \
	vim \
	ssh \
	git \
	build-essential \
	python-dev \
	python-pip \
	libpq-dev \
	perl-modules \
	libcache-memcached-perl \
	libcwd-guard-perl \
	libdbi-perl \
	libdbd-mysql-perl \
	libdbd-pg-perl \
	libmongodb-perl \
	libdata-dump-streamer-perl \
	libdatetime-perl \
	libdigest-md5-perl \
	libdigest-md5-file-perl \
	libfile-slurp-perl \
	libfilehandle-fmode-perl \
	libjson-perl \
	libstring-random-perl \
	libtemplate-perl \
	libwww-perl \
	libgetopt-long-descriptive-perl \
	liburi-encode-perl \
	libunicode-escape-perl \
	liblist-allutils-perl \
	libposix-strptime-perl \
	libberkeleydb-perl \
	libemail-simple-perl \
	libemail-sender-perl
RUN pip install biopython psycopg2 gspread openpyxl numpy leveldb
RUN cd /root \
	; mkdir bin \
	; git clone https://github.com/MG-RAST/pipeline
ADD ./mgrast_env.sh /root/

#
# If you you need a specific commit:
#
#RUN cd /root/pipeline/ && git pull && git reset --hard [ENTER HERE THE COMMIT HASH YOU WANT]