
## uninstall
* https://longhorn.io/docs/1.8.0/deploy/uninstall/

```
kubectl -n longhorn-system patch -p '{"value": "true"}' --type=merge lhs deleting-confirmation-flag
```


### CSI

```
k apply -k library/service/longhorn/external/kubernetes-csi-external-snapshote
```

## extra

```sh
kubectl delete ValidatingWebhookConfiguration longhorn-webhook-validator
```

on volumes cant be mounted:
https://longhorn.io/kb/troubleshooting-volume-with-multipath/
```


vim /etc/multipath.conf 

blacklist {
    devnode "^sd[a-z0-9]+"
}

sudo systemctl restart multipath-tools
systemctl restart multipathd.service
```


### Dependencis

```sh
# https://longhorn.io/docs/1.8.0/deploy/install/

curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v1.8.0/longhornctl-linux-amd64
chmod +x longhornctl
export KUBECONFIG=$PWD/.kubeconfig.yml
microk8s.config > $KUBECONFIG
./longhornctl check preflight
./longhornctl install preflight

# TO FIX on my ansible
cmp5:
  error:
  - 'Package nfs-common is not installed: package not installed'
  - 'Module dm_crypt is not loaded: failed to execute: nsenter [--mount=/host/proc/453185/ns/mnt --net=/host/proc/453185/ns/net grep dm_crypt /proc/modules], output , stderr : exit status 1'
  info:
  - Service iscsid is inactive, but it can still be activated by iscsid.socket
  - NFS4 is supported
  - Package open-iscsi is installed
  - Package cryptsetup is installed
  - Package dmsetup is installed
```


## Review

```
k describe -n longhorn-system nodes.longhorn.io
```

## Fixes

```
kubectl patch persistentvolume/pvc-9f1366f3-d8d8-49ec-9126-5bd-7b31c47b -n home -p '{"metadata":{"finalizers": []}}' --type=merge
k delete -n sys nodes.longhorn.io ape1
```


## Recovery

```sh
# mind: /var/snap/microk8s/common/var/lib/kubelet/plugins/kubernetes.io/csi/pv/
# mind: /var/lib/longhorn/replicas

snap install jq

cd /var/lib/longhorn/replicas
export RECOVERY='docker run -v /dev:/host/dev -v /proc:/host/proc -v $PWD/$PVC:/volume --privileged longhornio/longhorn-engine:v1.1.3 launch-simple-longhorn $PVC $PVCSIZE'

ls
export PVC=pvc-6683b256-23c0-491c-9ac5-70198da4bfc0-46f4191e
export PVC=pvc-9f1366f3-d8d8-49ec-9126-5bdc7e15fb42-25d3bf4b
export PVC=pvc-b4eabb95-02eb-41b5-b9ea-fb5f98a30e01-4d137a68
export PVC=pvc-d4c31e83-efa6-43b2-a870-77363f33db21-0c59011a
export PVC=pvc-fecce5e0-5895-42eb-9947-0571940f5f81-8444213e
export PVCSIZE=$(cat $PVC/volume.meta|jq ".Size")

mkdir recovery-$PVC
echo $RECOVERY |envsubst

# run in background
docker run --rm -v /dev:/host/dev -v /proc:/host/proc -v recovery-pvc-d4c31e83-efa6-43b2-a870-77363f33db21-0c59011a:/volume --privileged longhornio/longhorn-engine:v1.1.3 launch-simple-longhorn pvc-d4c31e83-efa6-43b2-a870-77363f33db21-0c59011a 6442450944
mount -t ext4 -o ro,defaults /dev/longhorn/$PVC recovery-$PVC
```
