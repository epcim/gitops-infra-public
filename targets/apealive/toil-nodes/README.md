

# Longhorn labels

No idea how to automate as of now.
There is no source for this, so it does not work. It could if I would serialize current node spec.

```
patchesJson6902:
- target:
    kind: Node
    name: cmp1-nuc11.*
    version: v1
  patch: |-
    - op: add
      path: /metadata/annotations/node.longhorn.io~1default-disks-config
      value: '[{"path":"/var/lib/longhorn","allowScheduling":true, "tags":["ssd", "nvme"]},
               {"path":"/var/lib/longhornDiskA","allowScheduling":true,"storageReserved":1024,"tags":["hdd","slow"]},
               {"path":"/var/lib/longhornDiskB","allowScheduling":true,"storageReserved":1024,"tags":["hdd","slow"]}]'
      

  node.longhorn.io/default-disks-config: '[{"path":"/var/lib/longhorn","allowScheduling": true, "tags":["nvme", "ssd", "fast"]}]'
  node.longhorn.io/default-disks-config: '[{"path":"/var/lib/longhorn","allowScheduling": true, "tags":["hdd", "slow"]}]'


  # nefunguje
  kubectl patch node cmp1-nuc11 -p '{"metadata":{"annotations":{"node.longhorn.io/default-disks-config": "[{"path":"/var/lib/longhorn","allowScheduling": true, "tags":["ssd", "nvme"]}]"}}}'
```


