# MG-RAST dockerfiles

FROM	debian
MAINTAINER The MG-RAST team

RUN apt-get update && apt-get install -y \
	apt-utils 	\
	bowtie2 	\
	build-essential \
	cdbfasta 	\
	cd-hit		\
	git 		\
	jellyfish 	\
	make 		\
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
	python-biopython \
	python-dev \
	python-pip \ 					
	python-leveldb \
	perl-modules \
   	python-numpy \
	python-scipy \
	unzip \
	wget 

# ###########
# copy files into image
RUN mkdir -p mkdir -p /root/pipeline
COPY mgrast_env.sh awecmd bin conf lib /root/pipeline/
COPY usearch superblat /usr/local//bin/
RUN chmod 555  /usr/local/bin/* && strip /usr/local/bin/*

#### install superblat (from binary in local dir) and BLAT from src
RUN cd /root \
	&& wget "http://users.soe.ucsc.edu/~kent/src/blatSrc35.zip" \
	&& unzip blatSrc35.zip && export C_INCLUDE_PATH=/root/include \
	&& export MACHTYPE=x86_64-pc-linux-gnu \
	&& cd blatSrc \
	&& make BINDIR=/usr/local/bin/ \
	&& strip /usr/local/bin/* \
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
	&& cd .. \
	&& echo "export PATH=/root/FragGeneScan/bin:\$PATH" >> /root/mgrast_env.sh


### install DIAMOND
RUN cd /root \
	&& git clone https://github.com/bbuchfink/diamond.git \
	&& cd diamond \
	&& cat build_simple.sh | sed s/-static//g > build_simple.sh \
	&& sh ./build_simple.sh \
	&& install -s -m555 diamond /usr/local/bin \
#	&& rm -rf /root/diamond
	
#
# If you you need a specific commit:
#
# RUN cd /root/pipeline/ && git pull && git reset --hard [ENTER HERE THE COMMIT HASH YOU WANT]
