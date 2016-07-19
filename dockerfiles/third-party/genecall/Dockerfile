# mgrast/pipeline-genecall

FROM mgrast/pipeline-base:latest
RUN apt-get update \
	&& apt-get install -y make \
	&& apt-get autoremove -y \
	; apt-get clean all
RUN cd /root \
	&& git clone https://github.com/wltrimbl/FGS.git FragGeneScan \
	&& cd FragGeneScan \
	&& make \
	&& mkdir bin \
	&& mv train bin/. \
	&& mv *.pl bin/. \
	&& mv FragGeneScan bin/. \
	&& cd .. \
	&& echo "export PATH=/root/FragGeneScan/bin:\$PATH" >> /root/mgrast_env.sh