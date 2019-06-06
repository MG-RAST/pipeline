# MG-RAST pipeline Dockerfile

FROM ubuntu
MAINTAINER The MG-RAST team (folker@mg-rast.org)
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
	cdbfasta 	\
	cd-hit		\
	cmake       \
	dh-autoreconf \
	emacs \
	git 		\
  libtbb-dev \
	libcwd-guard-perl \
	libberkeleydb-perl \
	libdata-dump-streamer-perl \
	libdatetime-perl \
	libdatetime-format-iso8601-perl \
	libdbi-perl 	\
	libdigest-md5-perl \
	libdigest-md5-file-perl \
	libdbd-pg-perl \
	libfile-slurp-perl \
	libfilehandle-fmode-perl \
	libgetopt-long-descriptive-perl \
	libjson-perl \
	liblist-allutils-perl \
	libpq-dev \
	libpng-dev \
	libposix-strptime-perl \
	libstring-random-perl \
	libtemplate-perl \
	liburi-encode-perl \
	libunicode-escape-perl \
	libwww-perl \
	liblog-log4perl-perl \
	libcapture-tiny-perl \
	make 		\
	nodejs \
	python-biopython \
	python-dev \
	python-leveldb \
	perl-modules \
  python-numpy \
	python-pika \
  python-pip \
	python-scipy \
	python-sphinx \
	unzip \
	wget \
  vim \
	curl \
	&& apt-get clean

### alphabetically sorted builds from source

### install bowtie2 2.3.5
RUN cd /root \
		&& wget -O bowtie2.zip https://github.com/BenLangmead/bowtie2/releases/download/v2.3.5/bowtie2-2.3.5-linux-x86_64.zip \
    && unzip bowtie2.zip \
    && rm -f bowtie2.zip \
    && cd bowtie2-* \
    && install bowtie2* /usr/local/bin/ \
    && cd /root \
    && rm -rf bowtie2*

### install autoskewer (requires bowtie)
RUN cd /root \
    && git clone http://github.com/MG-RAST/autoskewer \
    && cd autoskewer \
    && make install \
    && cd /root \
    && rm -rf autoskewer


### install DIAMOND
RUN cd /root \
	&& git clone https://github.com/bbuchfink/diamond.git \
	&& cd diamond \
	&& sh ./build_simple.sh \
	&& install -s -m555 diamond /usr/local/bin \
	&& cd /root \
	&& rm -rf diamond

### install ea-utils
RUN cd /root \
	&& git clone https://github.com/ExpressionAnalysis/ea-utils.git  \
	&& cd ea-utils/clipper \
	&& make fastq-multx \
	&& make fastq-join \
	&& make fastq-mcf \
	&& install -m755 -s fastq-multx /usr/local/bin \
	&& install -m755 -s fastq-join /usr/local/bin \
	&& install -m755 -s fastq-mcf /usr/local/bin \
	&& cd /root ; rm -rf ea-utils

### install FragGeneScan from our patched source in github
RUN cd /root \
	&& git clone https://github.com/MG-RAST/FGS.git FragGeneScan \
	&& cd FragGeneScan \
	&& make \
	&& mkdir bin \
	&& mv train bin/. \
	&& mv *.pl bin/. \
	&& cp -r bin/train /usr/local/bin/ \
	&& install -s -m555 FragGeneScan /usr/local/bin/. \
	&& install -m555 -t /usr/local/bin/. bin/*.pl \
	&& make clean \
	&& cd /root ; rm -rf FragGeneScan
	

### install jellyfish 2.2.6 from source (2.2.8 from repo is broken)
RUN cd /root \
    && wget -O jellyfish.tar.gz https://github.com/gmarcais/Jellyfish/releases/download/v2.2.6/jellyfish-2.2.6.tar.gz \
    && tar xfvz jellyfish.tar.gz \
    && rm -f jellyfish.tar.gz \
    && cd jelly*  \
    && ./configure \
    && make install \
    && cd /root \
    #&& rm -rf jelly*

### install prodigal
RUN cd /root \
    && wget -O Prodigal.tar.gz https://github.com/hyattpd/Prodigal/archive/v2.6.3.tar.gz \
    && tar xf Prodigal.tar.gz \
    && cd Prodigal* \
    && make \
    && make install \
    && strip /usr/local/bin/prodigal \
    && make clean \
    && cd /root ; rm -rf Prodigal*

### install sortmerna 2.1b
RUN cd /root \
	&& wget -O sortmerna-2.tar.gz https://github.com/biocore/sortmerna/archive/2.1b.tar.gz \
	&& tar xvf sortmerna-2.tar.gz \
	&& cd sortmerna-2* \
	&& sed -i 's/^\#define READLEN [0-9]*/#define READLEN 500000/' include/common.hpp \
	&& ./configure \
  && make install \
  && make clean \
  && strip /usr/local/bin/sortmerna* \
  && cd /root ; rm -rf sortmerna-2*

### install skewer
RUN cd /root \
    && git clone https://github.com/teharrison/skewer \
    && cd skewer \
    && make \
    && make install \
    && make clean \
    && cd /root ; rm -rf skewer

### install vsearch 2.12.0
RUN cd /root \
	  && wget -O vsearch-2.tar.gz https://github.com/torognes/vsearch/archive/v2.12.0.tar.gz \
		&& tar xzf vsearch-2.tar.gz  \
		&& cd vsearch-2* \
		&& sh ./autogen.sh \
		&& ./configure --prefix=/usr/local/ \
		&& make \
		&& make install \
		&& make clean \
		&& strip /usr/local/bin/vsearch* \
		&& cd /root ; rm -rf vsearch-2*

### install CWL runner
RUN pip install --upgrade pip
RUN pip install --upgrade cwlref-runner typing


# for jellyfish (ugly)
ENV LD_LIBRARY_PATH=/usr/local/lib

# copy files into image
COPY CWL /CWL/
COPY mgcmd/* bin/* /usr/local/bin/
COPY lib/* /usr/local/lib/site_perl/
