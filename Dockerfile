# MG-RAST pipeline Dockerfile

FROM ubuntu:20.04
LABEL Maintainer="wilke@anl.gov"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update -y 

RUN apt install -y 	cdbfasta 	
RUN apt install -y	cd-hit		
RUN apt install -y	cmake       
RUN apt install -y	dh-autoreconf 
RUN apt install -y	emacs 
RUN apt install -y	git 	
RUN apt install -y  libtbb-dev \
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
	nodejs 

RUN apt install -y \
	python3-biopython \
	python3-dev \
	# python3-leveldb \
	perl-modules \
  	python3-numpy \
	python3-pika \
  	python3-pip \
	python3-scipy \
	python3-sphinx \
	unzip \
	wget \
  	vim \
	curl \
	python-is-python3 \
	&& apt-get clean

RUN pip3 install leveldb

### alphabetically sorted builds from source

### install latest bowtie2 release
RUN cd /root \
	&& curl -s https://api.github.com/repos/BenLangmead/bowtie2/releases/latest  \
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
RUN wget http://github.com/bbuchfink/diamond/archive/v2.0.15.tar.gz \
	&& tar xzf v2.0.15.tar.gz \ 
	&& cd diamond-2.0.15 \ 
	&& mkdir bin \ 
	&& cd bin \ 
	&& cmake .. \
	&& make -j4 \
	&& make install

#	&& install -s -m555 diamond /usr/local/bin \

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
RUN apt install -y jellyfish

# cd /root \
#     && wget -O jellyfish.tar.gz https://github.com/gmarcais/Jellyfish/releases/download/v2.3.0/jellyfish-2.3.0.tar.gz \
#     && tar xfvz jellyfish.tar.gz \
#     && rm -f jellyfish.tar.gz \
#     && cd jelly*  \
#     && ./configure \
#     && make install \
#     && cd /root \
#     && rm -rf *jelly*

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

### install sortmerna 
RUN cd /root && wget https://github.com/biocore/sortmerna/releases/download/v4.3.6/sortmerna-4.3.6-Linux.sh \
	&& mkdir build \
	&& bash ./sortmerna-4.3.6-Linux.sh --skip-license --prefix=/root/build \
	&& install ./build/bin/sortmerna /usr/local/bin \
	&& cd /root \
	&& rm -rf sortmerna*




### install skewer
RUN apt update -y && apt-cache policy g++-8 && apt-cache show g++-8 && apt install -y  g++-8
# RUN cd /root \
#     && git clone https://github.com/relipmoc/skewer 
RUN cd /root && git clone https://github.com/wltrimbl/skewer.git \
    && cd skewer \
    && make \
    && make install \
    && make clean \
    && cd /root \
    && rm -rf skewer

### install latest vsearch release
RUN cd /root \
	&& wget https://github.com/torognes/vsearch/archive/v2.22.1.tar.gz \
	&& tar xzf v2.22.1.tar.gz \
	&& cd vsearch-2.22.1 \
	&& ./autogen.sh \
	&& ./configure CFLAGS="-O3" CXXFLAGS="-O3" \
	&& make \
	&& make install  # as root or sudo make install


### install CWL runner
RUN pip install --upgrade pip
RUN pip install --upgrade cwlref-runner typing statistics


# for jellyfish (ugly)
ENV LD_LIBRARY_PATH=/usr/local/lib

# copy files into image
COPY CWL /CWL/
COPY mgcmd/* bin/* /usr/local/bin/
COPY lib/* /usr/local/lib/site_perl/
