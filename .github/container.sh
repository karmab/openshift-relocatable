#!/bin/bash

set -ex

curl -Ls https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > jq
curl -k -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz | tar zxf - oc
podman build -t quay.io/karmab/openshift-relocatable:latest -f Dockerfile .
podman login -u $QUAY_USERNAME -p $QUAY_PASSWORD quay.io
podman push quay.io/karmab/openshift-relocatable:latest
