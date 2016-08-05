# MG-RAST dockerfiles

FROM	debian
MAINTAINER The MG-RAST team

ENV DEBIAN_FRONTEND noninteractive
<<<<<<< HEAD

=======
RUN apt-get update -qq && apt-get install -y locales -qq && locale-gen en_US.UTF-8 en_us && dpkg-reconfigure locales && dpkg-reconfigure locales && locale-gen C.UTF-8 && /usr/sbin/update-locale LANG=C.UTF-8
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8

RUN echo 'DEBIAN_FRONTEND=noninteractive' >> /etc/environment
>>>>>>> MG-RAST/master

RUN apt-get update && apt-get install -y \
	bowtie2 	\
	cdbfasta 	\
	cd-hit		\
	dh-autoreconf \
	git 		\
	subversion  \
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
	liblog-log4perl-perl \
	locales \
	make 		\
	python-biopython \
	python-dev \
	python-leveldb \
	perl-modules \
   	python-numpy \
	python-scipy \
	python-sphinx \
	unzip \
	wget
	

RUN echo 'DEBIAN_FRONTEND=noninteractive' >> /etc/environment
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales

# ###########
# copy files into image
COPY awecmd/* bin/* /usr/local/bin/
COPY lib/* /usr/local/lib/site_perl/
COPY superblat /usr/local/bin/
RUN chmod 555 /usr/local/bin/* && strip /usr/local/bin/superblat

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
	&& cd .. \
    && rm -rf /root/vsearch-2.02 /root/v2.0.2.tar.gz

### install Qiime licensed uclust
RUN wget -O /usr/local/bin/uclust http://www.drive5.com/uclust/uclustq1.2.22_i86linux64 \
    && chmod +x /usr/local/bin/uclust

### install Qiime python libs
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
