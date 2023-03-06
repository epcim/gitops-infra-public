
## K8s

## Deployment

### Ansible

Deployed and configured by:
- https://github.com/epcim/ansible-infra

### Firewall

- https://github.com/canonical/microk8s/issues/2418

```sh
sudo ufw allow in on cali+
sudo ufw allow out on cali+
```

### Nodes 

#### Labels

```
kubectl label nodes cmp1 type=main

kubectl label nodes cmp2 type=pool
kubectl label nodes cmp3 type=pool
```

#### confnigure non admin user

```
sudo usermod -a -G microk8s ubuntu
sudo chown -f -R ubuntu ~/.kube
newgrp microk8s

sudo ufw allow 25000
sudo ufw allow 19001/tcp

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

Change default storageclass:
```
kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

### bridge hostpath to external disks

specific to my env, needs to be done manually after apps are synced:
```
# k8s microk8s-hostpath
/mnt/DiskA/k8s-pvc/syncthing     /var/snap/microk8s/common/default-storage/home-syncthing-data-pvc-8ffc68e8-08ff-45d2-9d31-c75177c53ff6 none bind
/mnt/DiskA/k8s-pvc/minio-backup  /var/snap/microk8s/common/default-storage/sys-minio-backup-pvc-2280e2fb-fec5-453f-b2a7-e927b5ae31ee none bind
```


## Networking

### Ports

- https://microk8s.io/docs/services-and-ports

## Cluster

### to add node

```
sudo microk8s add-node
sudo microk8s join ...
```

### Advertise IPs

Manually set advertise IPs.

Internal IP
- https://github.com/ubuntu/microk8s/issues/2402

```
microk8s stop

cat <<-EOF >> /var/snap/microk8s/current/args/kubelet
--node-ip=10.10.1.11
EOF

cat <<-EOF >> /var/snap/microk8s/current/args/kube-apiserver
--advertise-address=10.10.1.11
EOF

microk8s start

microk8s kubectl get nodes -o wide

echo "$(microk8s kubectl get nodes -o wide | awk 'NR>1{ print $6, $1 }')" >> /etc/hosts
```

Pod CIDR
- https://microk8s.io/docs/change-cidr


### Recovery HA

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
