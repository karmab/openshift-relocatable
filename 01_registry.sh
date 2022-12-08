dnf -y install httpd-tools
REGISTRY_USER=dummy
REGISTRY_PASSWORD=dummy
DOMAIN=$(oc get ingresscontroller -n openshift-ingress-operator default -o jsonpath='{.status.domain}')
REGISTRY_NAME=registry-registry.$DOMAIN
BASEDIR=registry-data
mkdir $BASEDIR
mkdir -p $BASEDIR/{auth,certs}
openssl req -newkey rsa:4096 -nodes -sha256 -keyout $BASEDIR/certs/domain.key -x509 -days 3650 -out $BASEDIR/certs/domain.crt -subj "/C=US/ST=Madrid/L=Chamberi/O=Karmalabs/OU=Guitar/CN=$REGISTRY_NAME" -addext "subjectAltName=DNS:$REGISTRY_NAME"
cp $BASEDIR/certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract
htpasswd -bBc $BASEDIR/auth/htpasswd $REGISTRY_USER $REGISTRY_PASSWORD
oc create ns registry
oc create secret tls registry-certs --cert=$BASEDIR/certs/domain.crt --key=$BASEDIR/certs/domain.key -n registry
oc create secret generic registry-auth --from-file=$BASEDIR/auth/htpasswd -n registry
oc create -f 01_registry.yml
REGISTRY_POD=$(oc -n registry get pod  -l app=registry -o name)
oc wait -n registry --for=condition=Ready $REGISTRY_POD
