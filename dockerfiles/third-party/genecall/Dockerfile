FROM mgrast/base:latest
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