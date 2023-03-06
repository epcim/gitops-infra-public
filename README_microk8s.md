
## K8s

### K8s deployment

#### Labels

```
kubectl label nodes ape1 type=main
kubectl label nodes dpvm1 type=pool
```

#### Nodes

Plugins:
```
#microk8s enable dns
microk8s enable dns:192.168.96.1    # use local router, for local static/discovery
microk8s enable helm3
microk8s enable storage             # local storage
```

Longhorn:
```
apt-get install open-iscsi
```

### Upgrades
- https://microk8s.io/docs/upgrading

```
microk8s kubectl drain <node> --ignore-daemonsets
sudo snap refresh microk8s --channel=1.21/stable
microk8s.kubectl get no
microk8s kubectl uncordon <node>
```


## Storageclass

```
kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```



## K8s at OSX (DEPRECATED)

##  Add bridge1  (not needed)
> System Preferences, then click Network .
> Click the Action pop-up menu , then choose Manage Virtual Interfaces.
> Click the Add button , choose New Bridge, then select the interfaces to include in the bridge.

sudo multipass set local.bridged-network=bridge1


## Workarounds for multipass vm


```
sudo su -

cat <<-EOF >> /etc/pf.conf
# k8s
k8s = "{ 192.168.124.0/27 }"
k8s_tcp = "{ 30000:32767 }"
k8s_udp = "{ 30000:32767 }"
pass in inet proto tcp from <k8s> to <k8s> port 25000 no state
pass in inet proto tcp from <k8s> to <k8s> port \$k8s_tcp no state
pass in inet proto udp from <k8s> to <k8s> port \$k8s_udp no state

EOF
pfctl -f /etc/pf.conf


cat <<-EOF >> /etc/sysctl.conf
net.inet.ip.forwarding=1
EOF
sysctl -w net.inet.ip.forwarding=1
```


## Virtualbox OSX issue

```
cd /Library/Application\ Support/VirtualBox/
for f in *.kext; do echo $f; kmutil load -p $f; done
```

## Open firewall

- https://blog.neilsabol.site/post/quickly-easily-adding-pf-packet-filter-firewall-rules-macos-osx/

## for bridged interface (osx)
- https://multipass.run/docs/additional-networks
- older: https://discourse.ubuntu.com/t/using-virtualbox-in-multipass-on-macos/16591

sudo multipass set local.driver=virtualbox

## launch

sudo multipass launch --mem 8G --disk 80G --name microk8s-vm
sudo multipass launch --mem 8G --disk 80G --network name=bridge1,mode=auto --name dpvm1
#
sudo multipass set local.bridged-network=en7
sudo multipass launch --mem 8G --disk 80G --cpus 2 --bridged --name dpvm1
#sudo multipass launch --mem 8G --disk 80G --cpus 2 --network name=bridged,mode=auto,mac=52:54:00:E2:C6:6B --name dpvm1

multipass list

multipass shell microk8s-vm

sudo apt-get install -y vim net-tools open-iscsi
cat <<-EOF >> ~/.bashrc
set -o vi
alias k=microk8s.kubectl
alias kgp="k get po -A -o wide"
alias ll="ls -la"
EOF


#sudo snap remove microk8s
sudo snap install microk8s --classic --channel=1.21
sudo microk8s enable dns:192.168.96.1
sudo microk8s enable helm3
sudo microk8s enable storage         

sudo usermod -a -G microk8s ubuntu
sudo chown -f -R ubuntu ~/.kube
newgrp microk8s

sudo ufw allow 25000
sudo ufw allow 19001/tcp

## to add node
sudo microk8s add-node
sudo microk8s join ...

## for bridged/natted nodes

Fix cluster internal IP

- https://github.com/ubuntu/microk8s/issues/2402#issuecomment-950884240

microk8s stop
NODE_IP=192.168.124.11
cat <<-EOF >>/var/snap/microk8s/current/args/kubelet
--node-ip=$NODE_IP
EOF
cat <<-EOF >> /var/snap/microk8s/current/args/kube-apiserver
--advertise-address=$NODE_IP
EOF
microk8s start
microk8s.kubectl get nodes -o wide

sudo microk8s refresh-certs

After Join, there is known bug, update kubelet once again

microk8s stop
NODE_IP=192.168.124.11
cat <<-EOF >>/var/snap/microk8s/current/args/kubelet
--node-ip=$NODE_IP
EOF
microk8s start

Review
cat /var/snap/microk8s/current/args/kubelet
cat /var/snap/microk8s/current/args/kube-apiserver

## ports
https://microk8s.io/docs/services-and-ports

## extensions

longhorn:
apt-get install open-iscsi


## purge

multipass stop microk8s-vm
multipass delete microk8s-vm
multipass purge


##

--leader-elect-lease-duration=60s
--leader-elect-renew-deadline=30s
Into these files:
/var/snap/microk8s/current/args/kube-controller-manager and /var/snap/microk8s/current/args/kube-scheduler

Then restart MicroK8s.


### Upgrade

FEATURES="ha-cluster helm3 storage"
FEATURES="helm3 storage"
for i in $FEATURES; do
 microk8s disable $i;
 microk8s enable $i;
done



## Networking

### Change subnets

Internal IP
- https://github.com/ubuntu/microk8s/issues/2402

```
microk8s stop

cat <<-EOF >> /var/snap/microk8s/current/args/kubelet
--node-ip=172.31.1.11
EOF

cat <<-EOF >> /var/snap/microk8s/current/args/kube-apiserver
--advertise-address=172.31.1.11
EOF

microk8s start

microk8s kubectl get nodes -o wide

echo "$(microk8s kubectl get nodes -o wide | awk 'NR>1{ print $6, $1 }')" >> /etc/hosts
```

Pod CIDR
- https://microk8s.io/docs/change-cidr


## Recovery HA

- https://discuss.kubernetes.io/t/recovery-of-ha-microk8s-clusters/12931

```
cd /var/snap/microk8s
microk8s stop
tar -czv *.yaml metadata* -f dqlite-conf.tar.gz /var/snap/microk8s/current/var/kubernetes/backend
tar -czv --exclude=*.yaml --exclude=metadata* -f dqlite-data.tar.gz /var/snap/microk8s/current/var/kubernetes/backend
scp dqlite-data.tar.gz cmp2-kvm:/tmp
scp dqlite-data.tar.gz cmp3-kvm:/tmp

microk8s start


#

cd /
tar xzvf /tmp/dqlite-data.tar.gz
cd /var/snap/microk8s/current/var/kubernetes/backend

```

- https://discuss.kubernetes.io/t/recovery-of-ha-microk8s-clusters/12931

* Ensure all cluster nodes are not running with sudo snap stop microk8s or sudo microk8s stop
* Take a backup of a known good node (in this example, node 1 or 2) and exclude the info.yaml, metadata1, metadata2 files. An example, creating a tarball of the data: tar -c -v -z --exclude=*.yaml --exclude=metadata* -f dqlite-data.tar.gz /var/snap/microk8s/current/var/kubernetes/backend. This will create dqlite-data.tar.gz, containing a known-good replica of the data.
* Copy the dqlite-data.tar.gz to any nodes with older data. For example, use scp.
* On a node(s) with non-fresh data, take the copied archive, switch to the root user with sudo su, and change directory to the / directory with cd /.
* Again on the node(s) with non-fresh data, decompress the archive. If you copied the archive to the /home/ubuntu directory with scp, then run tar zxfv /home/ubuntu/dqlite-data.tar.gz
* Verify that the updated files have been decompressed into /var/snap/microk8s/current/var/kubernetes, the latest sequence numbers on the data file filenames should match between hosts.
* Prior to the next step, check the files in /var/snap/microk8s/current/var/kubernetes/backend and compare the files on each node. Make sure that the data files (the numbered dqlite files, e.g. 0000000002834690-0000000002835307 match on each host. You can check sha256sum results for each file to be sure. The list of files should match on each node. Also check the same for the snapshot-* files in the same directory. Once you are sure these files match, proceed to the next step.
* Start each node, one at a time, starting with a server which previously had up to date data (in this example, that would be node 1 or node 2, not node 3). If all data files are now in sync, microk8s should start after a short delay, when running sudo microk8s start.
