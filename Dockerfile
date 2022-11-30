FROM quay.io/centos/centos:stream8
MAINTAINER Karim Boumedhel <karimboumedhel@gmail.com>
ADD oc /usr/bin/oc
RUN chmod 700 /usr/bin/oc
ADD jq /usr/bin/jq
RUN chmod 700 /usr/bin/jq
ADD . /root
RUN dnf -y install gettext openssl podman
ENTRYPOINT ["/bin/bash", "/root/deploy.sh"]
