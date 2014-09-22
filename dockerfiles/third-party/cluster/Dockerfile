FROM mgrast/base:latest
RUN cd /root \
	&& wget "https://cdhit.googlecode.com/files/cd-hit-v4.6.1-2012-08-27.tgz" \
	&& tar -zxvf cd-hit-v4.6.1-2012-08-27.tgz \
	&& cd cd-hit-v4.6.1-2012-08-27 \
	&& make \
	&& cp cd-hit cd-hit-est cd-hit-2d cd-hit-est-2d cd-hit-div cd-hit-454 ../bin \
	&& cd .. \
	&& rm -rf cd-hit-v4.6.1-2012-08-27 cd-hit-v4.6.1-2012-08-27.tgz
