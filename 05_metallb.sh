export API_PUBLIC_IP=${API_PUBLIC_IP:-192.168.122.243}
export INGRESS_PUBLIC_IP=${INGRESS_PUBLIC_IP:-192.168.122.242}
envsubst < 05_metallb.yaml.sample | oc create -f -
