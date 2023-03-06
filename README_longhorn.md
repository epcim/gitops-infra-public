

## Fixes

```
kubectl patch persistentvolume/pvc-9f1366f3-d8d8-49ec-9126-5bd-7b31c47b -n home -p '{"metadata":{"finalizers": []}}' --type=merge
k delete -n sys nodes.longhorn.io ape1

kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## Recovery

```
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



pvc-9f1366f3 - postgres
pvc-d4c31e83 - home assistant


```
