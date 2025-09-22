

## PVC

Patch to retain:
```
k get pv,pvc -A

echo xxx yyy ccc \
  | xargs -n1 |xargs -I% echo kubectl patch % -p \''{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'\'
```

## Scaling

All pods in namespace
```
NS=
for ns in $NS; do
  kubectl scale deploy -n $ns --replicas=0 --all
done
```

## Force delete

To show you what resources remain in the namespace:
```
kubectl api-resources --verbs=list --namespaced -o name \
  | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>
```

### Namespace

- https://stackoverflow.com/questions/52369247/namespace-stuck-as-terminating-how-i-removed-it
```sh
(
NAMESPACE=your-rogue-namespace
kubectl proxy &
kubectl get namespace $NAMESPACE -o json |jq '.spec = {"finalizers":[]}' >temp.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize
)
```

or 
```sh
NS=
kubectl get namespace "$NS" -o json   | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/"   | kubectl replace --raw /api/v1/namespaces/$NS/finalize -f -
```



## Migrations

### move PV between namespaces

```
NAMESPACE1=sre
NAMESPACE2=gitops
PV=
PVC=data-gitea-0
PVC=data-gitea-0-postgresql

k get pv -A
k get pvc -A
kubectl patch pv "$PV" -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl describe pv "$PV" | grep -e Reclaim

kubectl delete pvc -n "$NAMESPACE1" "$PVC"

kubectl patch pv "$PV" -p '{"spec":{"claimRef":{"namespace":"'$NAMESPACE2'","name":"'$PVC'","uid":null}}}'
kubectl get pv "$PV" -o yaml | grep -v " f:" >| /tmp/pvc.yml

# add this annot
# kubectl.kubernetes.io/last-applied-configuration: ""
# add this to root
# uuid: $(uuidgen)
# uuid: D944BBBD-75C5-4687-9C32-A30903325772

❯ cat /tmp/pvc2.yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-gitea-0
  namespace: gitops
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: microk8s-hostpath


grep -v -e "uid:" -e "resourceVersion:" -e "namespace:" -e "selfLink:"  /tmp/pvc.yml | kubectl -n "$NAMESPACE2" apply -f -

PVCUID=$( kubectl get -n "$NAMESPACE2" pvc "$PVC" -o custom-columns=UID:.metadata.uid --no-headers )

kubectl patch pv "$PV" -p '{"spec":{"claimRef":{"uid":"'$PVCUID'","name":null}}}'

kubectl patch pv "$PV" -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'





```

