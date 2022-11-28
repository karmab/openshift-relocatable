DOMAIN=$(oc get ingresscontroller -n openshift-ingress-operator default -o jsonpath='{.status.domain}')
export REGISTRY_NAME=registry-registry.$DOMAIN
BASEDIR=registry-data
oc create configmap registry-config --from-file=$REGISTRY_NAME=$BASEDIR/certs/domain.crt -n openshift-config
oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' --type=merge
envsubst < 04_icsp.yml.sample | oc create -f -
