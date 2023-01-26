This repo contains scripts to illustrate how to create a relocatable cluster and how to actually relocate it

## Base cluster

The cluster will use a private network cidr (Our example uses 192.168.7.0/24) and two public vips, one for public api traffic and the other for public ingress.

For all the nodes of the cluster, we:

- set a static with the private cidr on top of the default nic. This is achieved with a systemd unit that adds the configuration after br-ex bridge is set and before crio and kubelet start. Each node is launched with extra kernel arguments, `relocateip` and `relocatenetmask` and a [a machineconfig](10-relocate-ip.yml.sample) that leverages script `relocate-ip.sh`
- configure kubelet to use the corresponding static ip. For this, a machine config creating the file `/etc/default/nodeip-configuration` with content such as `KUBELET_NODEIP_HINT=192.168.7.0` can be injected.
- set api vip and ingress vip using the private cidr
- deploy metallb operator deployed and configure two services using public vips pointing to api and ingress
- optionally deploy an embedded registry using storage on the node (typically odf or lvmo)

For production usage, proper DNS records as per the official documentation need to be pointing to ingress and api public ips.

## Deploying with aicli/kcli (Optional)

### kcli

We can create a cluster fulfilling those requirements on libvirt using kcli only for testing purposes. We need a temporary ip on default bridge to be able to communicate with the private cidr.

```
ip addr add 192.168.7.1/24 dev virbr0
kcli create cluster openshift --pf params_kcli.yml relocate

```
Note that for relocating such a virtual cluster, ctlplanes would need to be exported/imported.

### aicli

Support for relocation is present in aicli so we can deploy such a cluster with a parameter file such as [this one](aicli_parameters.yml) and optionally creating vms first 

```
kcli create plan -f kcli_plan.yml
aicli create deployment --pf aicli_parameters.yml relocate

```

## Manual Relocation steps

The following steps are needed:

- When the new location doesn't have internet access:
  - Deploy a disconnected registry within the cluster
  - Mirror openshift and olm content.
  - Create imagecontentsourcepolicies so that the cluster points to itself for content.
- Set metallb to access api and ingress from outside the cluster:
  - Create two ip address pools mapping one to the public api ip and the other to the public ingress ip.
  - Create a L2 advertisement for those pools.
  - Create two loadbalancer based services for each kind of traffic.
  
You can find different numbered scripts covering those tasks.

Alternatively, you can run the steps by editing the env variables in the [relocate pod spec](relocate.yaml) to match your environment and run it.

### Relocation simulation

After network for the public interfaces has changed, the cluster should still be accessible using the 192.168.7.0/24.

In order to access it from the outside, the following steps are needed:

- Update the ip address pools with new public ips.
- Remove old lb ips from the loadbalancer services so that the new ones get used, for instance by running:

```
oc patch svc/metallb-api -n openshift-kube-apiserver --type json --patch '[{ "op": "remove", "path": "/status/loadBalancer"}]'
oc patch svc/metallb-ingress -n openshift-ingress --type json --patch '[{ "op": "remove", "path": "/status/loadBalancer"}]'
```
At this point the cluster should be accessible through the new ips.

