# mgrast/pipeline-qc

FROM mgrast/pipeline-base:latest
RUN apt-get update \
    && apt-get install -y curl subversion tar make \
	&& apt-get autoremove -y \
	; apt-get clean all
RUN pip install sphinx
## cdbfasta
RUN cd /root \
	&& curl -L "http://sourceforge.net/projects/cdbfasta/files/latest/download?source=files" > cdbfasta.tar.gz \
	&& tar -zxf cdbfasta.tar.gz \
	&& cd cdbfasta \
	&& make \
	&& cp cdbfasta ../bin/. \
	&& cp cdbyank ../bin/. \
	&& cd .. \
	&& rm -rf cdbfasta cdbfasta.tar.gz
## jellyfish
RUN cd /root \
	&& curl -O "http://www.cbcb.umd.edu/software/jellyfish/jellyfish-1.1.11.tar.gz" \
	&& tar -zxf jellyfish-1.1.11.tar.gz && cd jellyfish-1.1.11 \
	&& ./configure --prefix=/root \
	&& make \
	&& make install \
	&& cd .. \
	&& rm -rf jellyfish-1.1.11 jellyfish-1.1.11.tar.gz
## uclust
RUN cd /root \
	&& curl -L "www.drive5.com/uclust/uclustq1.2.22_i86linux64" > bin/uclust \
	&& chmod +x bin/uclust 
## qiime python libs
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

