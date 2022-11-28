PULL_SECRET=pull.json
DOMAIN=$(oc get ingresscontroller -n openshift-ingress-operator default -o jsonpath='{.status.domain}')
REGISTRY_NAME=registry-registry.$DOMAIN
REGISTRY_USER=dummy
REGISTRY_PASSWORD=dummy
oc extract -n openshift-config secret/pull-secret --to=.
mv .dockerconfigjson $PULL_SECRET
KEY=$( echo -n $REGISTRY_USER:$REGISTRY_PASSWORD | base64)
jq ".auths += {\"$REGISTRY_NAME\": {\"auth\": \"$KEY\",\"email\": \"jhendrix@karmalabs.corp\"}}" < $PULL_SECRET > temp.json
cat temp.json | tr -d [:space:] > $PULL_SECRET
oc -n openshift-config create secret generic pull-secret --from-file=.dockerconfigjson=$PULL_SECRET --dry-run=client -o yaml | oc -n openshift-config apply --filename=-

OPENSHIFT_RELEASE_IMAGE=$(oc get clusterversion version -o jsonpath='{.status.desired.image}')
OCP_RELEASE=$(oc get clusterversion version -o jsonpath='{.status.desired.version}')-x86_64
DISCONNECTED_PREFIX=openshift/release
DISCONNECTED_PREFIX_IMAGES=openshift/release-images
echo oc adm release mirror -a $PULL_SECRET --from=$OPENSHIFT_RELEASE_IMAGE  --to-release-image=$REGISTRY_NAME/$DISCONNECTED_PREFIX_IMAGES:${OCP_RELEASE} --to=$REGISTRY_NAME/$DISCONNECTED_PREFIX
oc adm release mirror -a $PULL_SECRET --from=$OPENSHIFT_RELEASE_IMAGE  --to-release-image=$REGISTRY_NAME/$DISCONNECTED_PREFIX_IMAGES:${OCP_RELEASE} --to=$REGISTRY_NAME/$DISCONNECTED_PREFIX
