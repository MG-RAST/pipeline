TARGET ?= /usr/local/bin
VERSION ?= 0.9.26

all: update-pipeline deploy-pipeline update-client restart-client |

update-pipeline:
	git pull origin master

deploy-pipeline:
	cd awecmd; for X in *; do ln -f -s /root/pipeline/awecmd/$$X $(TARGET)/$$X; done
	cd bin; for X in *; do ln -f -s /root/pipeline/bin/$$X $(TARGET)/$$X; done

update-client:
	-mkdir -p /etc/awe/
	rm -f /etc/awe/awe-client
	cd /etc/awe; wget https://github.com/MG-RAST/AWE/releases/download/v$(VERSION)/awe-client
	chmod +x /etc/awe/awe-client
	ln -s /etc/awe/awe-client /usr/bin/awe-client

restart-client:
	/etc/init.d/awe-client stop
	rm -f /etc/awe/data/pidfile
	/etc/init.d/awe-client start