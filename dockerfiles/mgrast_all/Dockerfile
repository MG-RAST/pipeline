# MG-RAST dockerfiles
# mgrast/pipeline

FROM	ubuntu:16.04
MAINTAINER The MG-RAST team

## base dependencies
RUN apt-get update && apt-get install -y \
	git \
	subversion \
	wget \
	curl \
	make \
	zip \
	tar \
	libpng-dev \
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

## blat
ADD superblat /root/bin/superblat
RUN chmod +x /root/bin/superblat
RUN cd /root \
	&& wget "http://users.soe.ucsc.edu/~kent/src/blatSrc35.zip" \
	&& unzip blatSrc35.zip && export C_INCLUDE_PATH=/root/include \
	&& export MACHTYPE=x86_64-pc-linux-gnu \
	&& cd blatSrc \
	&& make BINDIR=/root/bin \
	&& cd .. \
	&& rm -rf blatSrc blatSrc35.zip

## bowtie
RUN cd /root \
	&& wget "http://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.2.3/bowtie2-2.2.3-source.zip" \
	&& cd /root ; unzip bowtie2-2.2.3-source.zip \
	&& cd /root/bowtie2-2.2.3 \
	&& make \
	&& cd /root/bowtie2-2.2.3 \
	&& cp bowtie2 bowtie2-align-l bowtie2-align-s bowtie2-build bowtie2-build-l bowtie2-build-s bowtie2-inspect bowtie2-inspect-l bowtie2-inspect-s ../bin \
	&& cd .. \
	&& rm -rf bowtie2-2.2.3 bowtie2-2.2.3-source.zip

## cluster
RUN cd /root \
	&& wget "https://cdhit.googlecode.com/files/cd-hit-v4.6.1-2012-08-27.tgz" \
	&& tar -zxvf cd-hit-v4.6.1-2012-08-27.tgz \
	&& cd cd-hit-v4.6.1-2012-08-27 \
	&& make \
	&& cp cd-hit cd-hit-est cd-hit-2d cd-hit-est-2d cd-hit-div cd-hit-454 ../bin \
	&& cd .. \
	&& rm -rf cd-hit-v4.6.1-2012-08-27 cd-hit-v4.6.1-2012-08-27.tgz

## genecall
RUN cd /root \
	&& git clone https://github.com/wltrimbl/FGS.git FragGeneScan \
	&& cd FragGeneScan \
	&& make \
	&& mkdir bin \
	&& mv train bin/. \
	&& mv *.pl bin/. \
	&& mv FragGeneScan bin/. \
	&& cd .. \
	&& echo "export PATH=/root/FragGeneScan/bin:\$PATH" >> /root/mgrast_env.sh

## search
ADD usearch /root/bin/usearch
RUN chmod +x /root/bin/usearch

## cdbfasta
RUN cd /root \
	&& curl -L "http://sourceforge.net/projects/cdbfasta/files/latest/download?source=files" > cdbfasta.tar.gz \
	&& tar -zxf cdbfasta.tar.gz \
	&& cd cdbfasta \
	&& make \
	&& cp cdbfasta ../bin/. \
	&& cp cdbyank ../bin/. \
	&& cd .. \
	&& rm -rf cdbfasta cdbfasta.tar.gz

## jellyfish
RUN cd /root \
	&& curl -O "http://www.cbcb.umd.edu/software/jellyfish/jellyfish-1.1.11.tar.gz" \
	&& tar -zxf jellyfish-1.1.11.tar.gz && cd jellyfish-1.1.11 \
	&& ./configure --prefix=/root \
	&& make \
	&& make install \
	&& cd .. \
	&& rm -rf jellyfish-1.1.11 jellyfish-1.1.11.tar.gz

## uclust
RUN cd /root \
	&& curl -L "www.drive5.com/uclust/uclustq1.2.22_i86linux64" > bin/uclust \
	&& chmod +x bin/uclust 

## qiime python libs
RUN svn co https://svn.code.sf.net/p/pprospector/code/trunk pprospector \
	&& git clone git://github.com/pycogent/pycogent.git \
	&& git clone git://github.com/biocore/pynast.git \
	&& git clone git://github.com/biocore/qiime.git \
	&& git clone git://github.com/biocore/biom-format.git \
	&& cd pycogent \
	&& git checkout c77e75ebf42c4a6379693cb792034efb9acd5891 \
	&& python setup.py install \
	&& cd ../pprospector \
	&& python setup.py install \
	&& cd ../pynast \
	&& git checkout 262acb14982c0fa48047c1e14ace950e77442169 \
	&& python setup.py install \
	&& cd ../qiime \
	&& git checkout d4333e2ea06af942f1f61148c4ccb02ffc438d6b \
	&& python setup.py install \
	&& cd ../biom-format \
	&& git checkout d5b85a85498783f45b7e1ab9c66aaa9460e1d10a \
	&& python setup.py install \
	&& cd .. \
	&& rm -rf pycogent pprospector pynast qiime biom-format

# cleanup
RUN apt-get autoremove -y; apt-get clean all

#
# If you you need a specific commit:
#
#RUN cd /root/pipeline/ && git pull && git reset --hard [ENTER HERE THE COMMIT HASH YOU WANT]