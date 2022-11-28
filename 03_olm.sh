PULL_SECRET="pull.json"
DOMAIN=$(oc get ingresscontroller -n openshift-ingress-operator default -o jsonpath='{.status.domain}')
export REGISTRY_NAME=registry-registry.$DOMAIN
export OCP_RELEASE=$(oc get clusterversion version -o jsonpath='{.status.desired.version}' | cut -d'.' -f 1,2)

# Add extra registry keys
#curl -o /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv https://www.redhat.com/security/data/55A34A82.txt
#jq ".transports.docker += {\"registry.redhat.io/redhat/certified-operator-index\": [{\"type\": \"signedBy\",\"keyType\": \"GPGKeys\",\"keyPath\": \"/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv\"}], \"registry.redhat.io/redhat/community-operator-index\": [{\"type\": \"signedBy\",\"keyType\": \"GPGKeys\",\"keyPath\": \"/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv\"}], \"registry.redhat.io/redhat/redhat-marketplace-operator-index\": [{\"type\": \"signedBy\",\"keyType\": \"GPGKeys\",\"keyPath\": \"/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-isv\"}]}" < /etc/containers/policy.json > /etc/containers/policy.json.new
#mv /etc/containers/policy.json.new /etc/containers/policy.json

REGISTRY_USER="dummy"
REGISTRY_PASSWORD="dummy"
podman login -u $REGISTRY_USER -p $REGISTRY_PASSWORD $REGISTRY_NAME
REDHAT_CREDS=$(cat $PULL_SECRET | jq .auths.\"registry.redhat.io\".auth -r | base64 -d)
RHN_USER=$(echo $REDHAT_CREDS | cut -d: -f1)
RHN_PASSWORD=$(echo $REDHAT_CREDS | cut -d: -f2)
podman login -u "$RHN_USER" -p "$RHN_PASSWORD" registry.redhat.io

which oc-mirror >/dev/null 2>&1
if [ "$?" != "0" ] ; then
  curl -sL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/oc-mirror.tar.gz | tar xvz -C .
  chmod +x oc-mirror
  export PATH=$PATH:.
fi

[ -d $HOME/.docker ] || mkdir -p $HOME/.docker
[ -f $HOME/.docker/config.json ] && cp $HOME/.docker/config.json $HOME/.docker/config.json.old
cp -f $PULL_SECRET $HOME/.docker/config.json

envsubst < 03_mirror-config.yaml.sample > 03_mirror-config.yaml

rm -rf oc-mirror-workspace || true
oc-mirror --config 03_mirror-config.yaml --max-per-registry 20 --ignore-history docker://$REGISTRY_NAME

oc apply -f oc-mirror-workspace/results-*/*imageContentSourcePolicy.yaml
oc apply -f oc-mirror-workspace/results-*/*catalogSource*

[ -f $HOME/.docker/config.json.old ] && mv $HOME/.docker/config.json.old $HOME/.docker/config.json
