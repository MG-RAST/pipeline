FROM mgrast/base:latest
RUN apt-get update && apt-get autoremove -y ; apt-get clean all
RUN apt-get install -y zip 
RUN cd /root && wget "http://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.2.3/bowtie2-2.2.3-source.zip" && cd /root ; unzip bowtie2-2.2.3-source.zip && cd /root/bowtie2-2.2.3 && make && cd /root/bowtie2-2.2.3 && cp bowtie2 bowtie2-align-l bowtie2-align-s bowtie2-build bowtie2-build-l bowtie2-build-s bowtie2-inspect bowtie2-inspect-l bowtie2-inspect-s ../bin ; cd .. ; rm -rf bowtie2-2.2.3 bowtie2-2.2.3-source.zip && apt-get autoremove -y ; apt-get clean all

