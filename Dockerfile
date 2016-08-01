# MG-RAST dockerfiles

FROM	debian
MAINTAINER The MG-RAST team

ENV LC_ALL UTF-8
RUN echo 'LC_ALL=UTF-8' >> /etc/environment 
ENV DEBIAN_FRONTEND noninteractive
RUN echo 'DEBIAN_FRONTEND=noninteractive' >> /etc/environment

RUN apt-get update && apt-get install -y \
	bowtie2 	\
	cdbfasta 	\
	cd-hit		\
	dh-autoreconf \
	git 		\
	jellyfish 	\
	libcwd-guard-perl \
	libberkeleydb-perl \
	libdata-dump-streamer-perl \
	libdatetime-perl \
	libdbi-perl 	\
	libdigest-md5-perl \
	libdigest-md5-file-perl \
	libdbd-pg-perl \
	libemail-simple-perl \
	libemail-sender-perl \
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
	make 		\
	python-biopython \
	python-dev \
	python-pip \ 					
	python-leveldb \
	perl-modules \
   	python-numpy \
	python-scipy \
	unzip \
	wget \
	&& rm -rf /usr/share/doc/ /usr/share/man/ /usr/share/X11/ /usr/share/i18n/ /usr/share/mime /usr/share/locale

# ###########
# copy files into image
COPY awecmd/* bin/* /usr/local/bin/
COPY lib/* /usr/local/lib/perl/perl5/
COPY usearch superblat /usr/local/bin/
RUN chmod 555 /usr/local/bin/* && strip /usr/local/bin/usearch && strip /usr/local/bin/superblat

#### install superblat (from binary in local dir) and BLAT from src
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
	&& rm -rf example .git \
	&& cd .. \
	&& echo "export PATH=/root/FragGeneScan/bin:\$PATH" >> /root/mgrast_env.sh

### install DIAMOND
RUN cd /root \
	&& git clone https://github.com/bbuchfink/diamond.git \
	&& mkdir -p /root/diamond \
	&& cd /root/diamond \
	# && cat build_simple.sh | sed s/-static//g > build_simple.sh \
	&& sh ./build_simple.sh \
	&& install -s -m555 diamond /usr/local/bin \
	&& rm -rf /root/diamond
	
### install vsearch 2.02
RUN cd /root \
	&& wget https://github.com/torognes/vsearch/archive/v2.0.2.tar.gz \
	&& tar xzf v2.0.2.tar.gz \
	&& cd vsearch-2.0.2 \
	&& ./autogen.sh \
	&& ./configure --prefix=/usr/local/ \
	&& make \
	&& make install \
	&& make clean \
	&& rm -rf /root/vsearch-2.02

### install qiime licensed uclust
RUN wget -O /usr/local/bin/uclust http://www.drive5.com/uclust/uclustq1.2.22_i86linux64 \
    && chmod +x /usr/local/bin/uclust
