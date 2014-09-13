FROM mgrast/base:20140912
RUN cd /root && git clone https://github.com/wltrimbl/FGS.git FragGeneScan && cd FragGeneScan && make && mkdir bin && mv train bin/. && mv *.pl bin/. && mv FragGeneScan bin/. && cd .. && ln -sf FragGeneScan/bin/* bin/.

