FROM quay.io/centos/centos:stream8
MAINTAINER Karim Boumedhel <karimboumedhel@gmail.com>
ADD . /root
ENTRYPOINT ["/bin/bash", "/root/deploy.sh"]
