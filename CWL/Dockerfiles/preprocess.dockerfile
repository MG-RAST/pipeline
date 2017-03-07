# MG-RAST qc dockerfile
FROM	debian
MAINTAINER The MG-RAST team

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -qq && \
  apt-get install -y locales -qq && \
  locale-gen en_US.UTF-8 en_us && \
  dpkg-reconfigure locales && \
  dpkg-reconfigure locales && \
  locale-gen C.UTF-8 && \
  /usr/sbin/update-locale LANG=C.UTF-8
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8

RUN echo 'DEBIAN_FRONTEND=noninteractive' >> /etc/environment

RUN apt-get update
# awe_preprocess.pl 
RUN apt-get install -y \
  libjson-perl \
  libdatetime-perl \
  libdatetime-format-iso8601-perl \
  libwww-perl \
  libcapture-tiny-perl \
  liblog-log4perl-perl 
# DRISEE  
RUN apt-get install -y \
  python-dev \
  python-biopython 
 

# copy files into image
COPY awecmd/* bin/* /usr/local/bin/
COPY lib/* /usr/local/lib/site_perl/



	




