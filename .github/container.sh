#!/bin/bash

set -ex

podman build -t quay.io/karmab/openshift-relocatable:latest -f Dockerfile .
podman login -u $QUAY_USERNAME -p $QUAY_PASSWORD quay.io
podman push quay.io/karmab/openshift-relocatable:latest
