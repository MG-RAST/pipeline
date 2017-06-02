# MG-RAST dockerfiles

FROM	debian
MAINTAINER The MG-RAST team

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -qq && apt-get install -y locales -qq && locale-gen en_US.UTF-8 en_us && dpkg-reconfigure locales && dpkg-reconfigure locales && locale-gen C.UTF-8 && /usr/sbin/update-locale LANG=C.UTF-8
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8

RUN echo 'DEBIAN_FRONTEND=noninteractive' >> /etc/environment

RUN apt-get update && apt-get install -y \
	bowtie2 	\
	cdbfasta 	\
	cd-hit		\
	cmake \
	dh-autoreconf \
	git 		\
	jellyfish 	\
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
	curl

#### install BLAT from src
RUN cd /root \
	&& wget "http://users.soe.ucsc.edu/~kent/src/blatSrc35.zip" \
	&& unzip blatSrc35.zip && export C_INCLUDE_PATH=/root/include \
	&& export MACHTYPE=x86_64-pc-linux-gnu \
	&& cd blatSrc \
	&& make BINDIR=/usr/local/bin/ \
	&& strip /usr/local/bin/blat \
	&& cd .. \
	&& rm -rf blatSrc blatSrc35.zip

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
	&& mkdir -p /root/diamond \
	&& cd /root/diamond \
	# && cat build_simple.sh | sed s/-static//g > build_simple.sh \
	&& sh ./build_simple.sh \
	&& install -s -m555 diamond /usr/local/bin \
	&& cd /root ; rm -rf /root/diamond
	

### install swarm 2.1.9
RUN cd /root \
	&& git clone https://github.com/torognes/swarm.git \
	&& cd swarm/src/ \
	&& make \
	&& install -m755 -s bin/* /usr/local/bin \
	&& install -m755 scripts/* /usr/local/bin \
	&& cd /root ; rm -rf swarm

### install fastqjoin from ea-utils
RUN cd /root \
	&& git clone https://github.com/ExpressionAnalysis/ea-utils.git  \
	&& cd ea-utils/clipper \
	&& make \
	&& install -m755 -s fastq-join /usr/local/bin/ \
	&& install -m755 -s fastq-multx /usr/local/bin/ \
	&& cd /root ; rm -rf /root/ea-utils

### install sortmerna
RUN cd /root \
	&& wget https://github.com/biocore/sortmerna/archive/2.1b.tar.gz \
	&& tar xvf 2.1b.tar.gz \
	&& cd sortmerna-2.1b \
	&& ./configure && make install && make clean

### install vsearch 2.43
RUN cd /root \
    && wget https://github.com/torognes/vsearch/archive/v2.4.3.tar.gz \
	&& tar xzf v2*.tar.gz \
	&& cd vsearch-2* \
	&& sh ./autogen.sh \
	&& ./configure --prefix=/usr/local/ \
	&& make \
	&& make install \
	&& make clean \
	&& cd /root ; rm -rf /root/vsearch-2* 

### install CWL runner
RUN pip install cwlref-runner

# copy files into image
COPY mgcmd/* bin/* /usr/local/bin/
COPY lib/* /usr/local/lib/site_perl/
COPY superblat /usr/local/bin/
RUN for i in /usr/local/bin/mgrast_* ; do awe=`echo $i | sed -e "s/mgrast_/awe_/g"` ; ln -s $i $awe ; done
RUN chmod 555 /usr/local/bin/* && strip /usr/local/bin/superblat
