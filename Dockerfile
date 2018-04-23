# MG-RAST pipeline Dockerfile

FROM debian
MAINTAINER The MG-RAST team

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -qq && apt-get install -y locales -qq && locale-gen en_US.UTF-8 en_us && dpkg-reconfigure locales && dpkg-reconfigure locales && locale-gen C.UTF-8 && /usr/sbin/update-locale LANG=C.UTF-8
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8

RUN echo 'DEBIAN_FRONTEND=noninteractive' >> /etc/environment

RUN apt-get update && apt-get install -y \
	cdbfasta 	\
	cd-hit		\
	cmake       \
	dh-autoreconf \
	git 		\
	jellyfish 	\
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
	curl

#### install BLAT from src
RUN cd /root \
	&& wget "http://users.soe.ucsc.edu/~kent/src/blatSrc35.zip" \
	&& unzip blatSrc35.zip && export C_INCLUDE_PATH=/root/include \
	&& export MACHTYPE=x86_64-pc-linux-gnu \
	&& cd blatSrc \
	&& make BINDIR=/usr/local/bin/ \
	&& strip /usr/local/bin/blat \
	&& cd /root ; rm -rf blatSrc blatSrc35.zip

### install FragGeneScan from our patched source in github
RUN cd /root \
	&& git clone https://github.com/wltrimbl/FGS.git FragGeneScan \
	&& cd FragGeneScan \
	&& make \
	&& mkdir bin \
	&& mv train bin/. \
	&& mv *.pl bin/. \
	&& install -s -m555 FragGeneScan bin/. \
	&& make clean \
	&& rm -rf example .git
ENV PATH /root/FragGeneScan/bin:$PATH

### install DIAMOND
RUN cd /root \
	&& git clone https://github.com/bbuchfink/diamond.git \
	&& cd diamond \
	&& sh ./build_simple.sh \
	&& install -s -m555 diamond /usr/local/bin \
	&& cd /root ; rm -rf diamond

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

### install sortmerna 2.1b
RUN cd /root \
	&& wget https://github.com/biocore/sortmerna/archive/2.1b.tar.gz \
	&& tar xvf 2*.tar.gz \
	&& cd sortmerna-2* \
	&& sed -i 's/^\#define READLEN [0-9]*/#define READLEN 500000/' include/common.hpp \
	&& ./configure \
    && make install \
    && make clean \
    && cd /root ; rm -rf sortmerna-2* 2*.tar.gz

### install vsearch 2.7.1
RUN cd /root \
    && wget https://github.com/torognes/vsearch/archive/v2.7.1.tar.gz \
	&& tar xzf v2*.tar.gz \
	&& cd vsearch-2* \
	&& sh ./autogen.sh \
	&& ./configure --prefix=/usr/local/ \
	&& make \
	&& make install \
	&& make clean \
	&& cd /root ; rm -rf vsearch-2* v2*.tar.gz

### install bowtie2 2.3.4.1
RUN cd /root \
    && wget -O bowtie2-2.3.4.1-linux-x86_64.zip 'https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.3.4.1/bowtie2-2.3.4.1-linux-x86_64.zip/download' \
    && unzip bowtie2-*.zip \
    && rm -f bowtie2-*.zip \
    && cd bowtie2-* \
    && cp bowtie2* /usr/local/bin/.

### install skewer
RUN cd /root \
    && git clone https://github.com/relipmoc/skewer \
    && cd skewer \
    && make \
    && make install \
    && make clean \
    && cd /root ; rm -rf skewer

### install autoskewer
RUN cd /root \
    && git clone http://github.com/MG-RAST/autoskewer \
    && cd autoskewer \
    && make
ENV PATH /root/autoskewer/:$PATH

### install CWL runner
RUN pip install cwlref-runner

# node.js version 7
RUN curl -sL https://deb.nodesource.com/setup_7.x | bash - ; \
    apt-get install -y nodejs

# copy files into image
COPY CWL /CWL/
COPY mgcmd/* bin/* /usr/local/bin/
COPY lib/* /usr/local/lib/site_perl/
COPY superblat /usr/local/bin/
RUN chmod 555 /usr/local/bin/* && strip /usr/local/bin/superblat
