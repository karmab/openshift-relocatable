#!/bin/sh

NIC={{ "ens3" if 'bootstrap' in name else 'br-ex' }}
IP={{ ip }}
NETMASK={{ netmask }}

grep -q $IP /etc/NetworkManager/system-connections/* && exit 0

connection=$(nmcli -t -f NAME,DEVICE c s -a | grep $NIC | grep -v ovs-port | grep -v ovs-if | cut -d: -f1)
nmcli connection modify "$connection" +ipv4.addresses $IP/$NETMASK ipv4.method auto
if [ "$NIC" == "br-ex" ] ; then 
 ip addr add $IP/$NETMASK dev $NIC
else
 nmcli dev reapply $NIC
fi
