cd /root
[ "$API_PUBLIC_IP" == "" ] && echo missing API_PUBLIC_IP && exit 1
[ "$INGRESS_PUBLIC_IP" == "" ] && echo missing INGRESS_PUBLIC_IP && exit 1
if [ "$REGISTRY" == "true" ] ; then
bash 01_registry.sh
bash 02_mirror.sh
bash 03_olm.sh
bash 04_switch_registry.sh
fi
bash 05_metallb.sh
