
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
