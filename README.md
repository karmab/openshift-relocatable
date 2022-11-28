This repo contains scripts to illustrate how to create a relocatable cluster and how to actually relocate it

## Base cluster

The cluster needs the following requisites to support relocation:

- A dedicated private network (Our example uses 192.168.7.0/24).
- A public network with two reserved ips, one to be used for public api traffic and the other for public ingress.
- a Given number of nodes with:
  - A nic on the public network.
  - Either:
    - A dedicated nic configured with private ip. This can be achieved in different ways:
      - Creating machine configs to create /etc/sysconfig/network-scripts/ifcfg files when using an UPI based approach.
      - Leveraging static networking support in baremetal IPI.
      - Nmstate configs when using ZTP.
    - Reusing the public nic to also host the private ip. With OVN, this will require a systemd unit to add the configuration after br-ex bridge is set and before crio and kubelet start
- Kubelet to use the corresponding static ip. For this, a machine config creating the file `/etc/default/nodeip-configuration` with content such as `KUBELET_NODEIP_HINT=192.168.7.0` can be injected.
- Api and ingress to be available through the private network (For instance by having vips).
- Metallb operator deployed.
- For production usage, proper DNS records as per the official documentation in place pointing to ingress and api public ips.

We can create a cluster fulfilling those requirements on libvirt using kcli

If using two nics,

```
kcli create network -c 192.168.7.0 -i ztpfw
kcli create cluster openshift --pf params_sdn.yml ztpfw
```

If using a single nic with ovn

```
ip addr add 192.168.7.1/24 dev virbr0
kcli create cluster openshift --pf params_ovn.yml ztpfw
```

## Relocation preparation

The following steps are needed:

- When the new location doesn't have internet access:
  - Deploy a disconnected registry within the cluster if the new location doesnt have internet access.
  - Mirror openshift and olm content.
  - Create imagecontentsourcepolicies so that the cluster points to itself for content.
- Set metallb to access api and ingress from outside the cluster:
  - Create two ip address pools mapping one to the public api ip and the other to the public ingress ip.
  - Create a L2 advertisement for those pools.
  - Create two loadbalancer based services for each kind of traffic.
  
 You can find different numbered scripts covering those tasks.

## Relocation simulation

After network for the public interfaces has changed, the cluster should still be accessible using the 192.168.7.0/24.

In order to access it from the outside, the following steps are needed:

- Update the ip address pools with new public ips.
- Remove old lb ips from the loadbalancer services so that the new ones get used, for instance by running:

```
oc patch svc/metallb-api -n openshift-kube-apiserver --type json --patch '[{ "op": "remove", "path": "/status/loadBalancer"}]'
oc patch svc/metallb-ingress -n openshift-ingress --type json --patch '[{ "op": "remove", "path": "/status/loadBalancer"}]'
```
At this point the cluster should be accessible through the new ips.

