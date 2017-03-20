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
  cd-hit		\
  cdbfasta 	\
  cmake \
  curl \
  dh-autoreconf \
  git 		\
  jellyfish 	\
  libberkeleydb-perl \
  libcapture-tiny-perl \
  libcwd-guard-perl \
  libdata-dump-streamer-perl \
  libdatetime-format-iso8601-perl \
  libdatetime-perl \
  libdbd-pg-perl \
  libdbi-perl 	\
  libdigest-md5-file-perl \
  libdigest-md5-perl \
  libfile-slurp-perl \
  libfilehandle-fmode-perl \
  libgetopt-long-descriptive-perl \
  libjson-perl \
  liblist-allutils-perl \
  liblog-log4perl-perl \
  libpng-dev \
  libposix-strptime-perl \
  libpq-dev \
  libstring-random-perl \
  libtemplate-perl \
  libunicode-escape-perl \
  liburi-encode-perl \
  libwww-perl \
  make 		\
  perl-modules \
  python-biopython \
  python-dev \
  python-leveldb \
  python-numpy \
  python-pika \
  python-scipy \
  python-sphinx \
  unzip \
  wget 
	


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
	
### install vsearch 2.40
RUN cd /root \
	&& wget https://github.com/torognes/vsearch/archive/v2.4.0.tar.gz \
	&& tar xzf v2.4.0.tar.gz \
	&& cd vsearch-2.4.0 \
	&& sh ./autogen.sh \
	&& ./configure --prefix=/usr/local/ \
	&& make \
	&& make install \
	&& make clean \
	&& cd /root ; rm -rf /root/vsearch-2* 

### install swarm 2.1.9
RUN cd /root \
	&& git clone https://github.com/torognes/swarm.git \
	&& cd swarm/src/ \
	&& make \
	&& install -m755 -s bin/* /usr/local/bin \
	&& install -m755 scripts/* /usr/local/bin \
	&& cd /root ; rm -rf swarm

### install fastqjoin from  ea-utils
RUN cd /root \
	&& git clone https://github.com/ExpressionAnalysis/ea-utils.git  \
	&& cd ea-utils/clipper \
	&& make fastq-join \
	&& install -m755 -s fastq-join /usr/local/bin/ \
	&& cd /root ; rm -rf /root/ea-utils

### install 
RUN cd /root \
	&& wget https://github.com/biocore/sortmerna/archive/2.1b.tar.gz \
	&& tar xvf 2.1b.tar.gz \
	&& cd sortmerna-2.1b \
	&& ./configure &&  make install && make clean

### install simka
#RUN cd /root \
#	&& git clone https://github.com/GATB/simka.git \
#	&& cd simka \
#	&& sh INSTALL \

# Install CWL
RUN apt-get install -y curl
RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"  \
  && python get-pip.py  \
  && pip install cwlref-runner \
  && rm get-pip.py

# copy files into image
COPY awecmd/* bin/* /usr/local/bin/
COPY lib/* /usr/local/lib/site_perl/
# COPY superblat /usr/local/bin/
RUN chmod 555 /usr/local/bin/* 
# && strip /usr/local/bin/superblat

