FROM mgrast/base:20140912
RUN apt-get update && apt-get install -y zip libpng-dev
RUN cd /root && wget "http://users.soe.ucsc.edu/~kent/src/blatSrc35.zip" && unzip blatSrc35.zip && export C_INCLUDE_PATH=/root/include && export MACHTYPE=x86_64-pc-linux-gnu && cd blatSrc && make BINDIR=/root/bin && cd .. && rm -rf blatSrc blatSrc35.zip

