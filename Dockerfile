# MG-RAST dockerfiles
# docker pull mgrast/pipeline-base && docker build -t mgrast/pipeline .

FROM	mgrast/pipeline-base
MAINTAINER The MG-RAST team

# copy files into image
COPY awecmd/* bin/* /usr/local/bin/
COPY lib/* /usr/local/lib/site_perl/
COPY superblat /usr/local/bin/
RUN chmod 555 /usr/local/bin/* && strip /usr/local/bin/superblat
