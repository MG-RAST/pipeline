# MG-RAST pipeline Dockerfile

FROM ubuntu:18.10
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
	libtbb-dev \
	libtemplate-perl \
	liburi-encode-perl \
	libunicode-escape-perl \
	libwww-perl \
	liblog-log4perl-perl \
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

### install latest bowtie2 release
RUN cd /root \
		&& 	curl -s https://api.github.com/repos/BenLangmead/bowtie2/releases/latest  \
		| grep tarball_url | cut -f4 -d\" | wget -O download.tar.gz -qi - \
		&& tar xzfp download.tar.gz \
    && rm -f download.tar.gz \
    && cd * \
    && make \
    && install bowtie2* /usr/local/bin/ \
    && cd /root \
    && rm -rf *bowtie2*

### install autoskewer (requires bowtie)
RUN cd /root \
    && git clone http://github.com/MG-RAST/autoskewer \
    && cd autoskewer \
    && make install \
    && cd /root \
    && rm -rf autoskewer

### install latest DIAMOND release
RUN cd /root \
	&& 	curl -s https://api.github.com/repos/bbuchfink/diamond/releases/latest  \
	| grep tarball_url | cut -f4 -d\" | wget -O download.tar.gz -qi - \
	&& tar xzfp download.tar.gz \
	&& rm -f download.tar.gz \
  && cd * \
	&& sh ./build_simple.sh \
	&& install -s -m555 diamond /usr/local/bin \
	&& cd /root \
	&& rm -rf *diamond*

### install latest ea-utils release
RUN cd /root \
	&& curl -s https://api.github.com/repos/ExpressionAnalysis/ea-utils/releases/latest  \
	| grep tarball_url | cut -f4 -d\" | wget -O download.tar.gz -qi - \
	&& tar xzfp download.tar.gz \
	&& rm -f download.tar.gz \
  && cd *ea-utils*/clipper \
	&& make fastq-multx \
	&& make fastq-join \
	&& make fastq-mcf \
	&& install -m755 -s fastq-multx /usr/local/bin \
	&& install -m755 -s fastq-join /usr/local/bin \
	&& install -m755 -s fastq-mcf /usr/local/bin \
	&& cd /root \
	&& rm -rf *ea-utils*

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
	&& cd /root \
	&& rm -rf FragGeneScan


### install jellyfish 2.2.6 from source (2.2.8 from repo is broken)
RUN cd /root \
    && wget -O jellyfish.tar.gz https://github.com/gmarcais/Jellyfish/releases/download/v2.2.6/jellyfish-2.2.6.tar.gz \
    && tar xfvz jellyfish.tar.gz \
    && rm -f jellyfish.tar.gz \
    && cd jelly*  \
    && ./configure \
    && make install \
    && cd /root \
    && rm -rf *jelly*

### install latest prodigal release
RUN cd /root \
		&& curl -s https://api.github.com/repos/hyattpd/Prodigal/releases/latest  \
		| grep tarball_url | cut -f4 -d\" | wget -O download.tar.gz -qi - \
		&& tar xzfp download.tar.gz \
		&& rm -f download.tar.gz \
		&& cd *Prodigal* \
    && make \
    && make install \
    && strip /usr/local/bin/prodigal \
    && make clean \
    && cd /root  \
		&& rm -rf *Prodigal*

	### install sortmerna 2.1b
	RUN cd /root \
	&& wget https://github.com/biocore/sortmerna/archive/2.1b.tar.gz \
	&& tar xvf 2*.tar.gz \
	&& cd sortmerna-2* \
	&& sed -i 's/^\#define READLEN [0-9]*/#define READLEN 500000/' include/common.hpp \
	&& ./configure \
	&& make install \
  && make clean \
  && cd /root \
	&& rm -rf sortmerna-2* 2*.tar.gz



### install skewer
RUN cd /root \
    && git clone https://github.com/teharrison/skewer \
    && cd skewer \
    && make \
    && make install \
    && make clean \
    && cd /root \
		&& rm -rf skewer

### install latest vsearch release
RUN cd /root \
		&& curl -s https://api.github.com/repos/torognes/vsearch/releases/latest  \
		| grep tarball_url | cut -f4 -d\" | wget -O download.tar.gz -qi - \
		&& tar xzfp download.tar.gz \
		&& rm -f download.tar.gz \
		&& cd * \
		&& sh ./autogen.sh \
		&& ./configure --prefix=/usr/local/ \
		&& make \
		&& make install \
		&& make clean \
		&& strip /usr/local/bin/vsearch* \
		&& cd /root \
		&& rm -rf *vsearch*



### install CWL runner
RUN pip install --upgrade pip
RUN pip install --upgrade cwlref-runner typing statistics


# for jellyfish (ugly)
ENV LD_LIBRARY_PATH=/usr/local/lib

# copy files into image
COPY CWL /CWL/
COPY mgcmd/* bin/* /usr/local/bin/
COPY lib/* /usr/local/lib/site_perl/
