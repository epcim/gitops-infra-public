

n=cmp2-kvm
kubectl patch node $n -p '{"metadata":{"labels":{"longhorn": "yes"}}}'
kubectl patch node $n -p '{"metadata":{"labels":{"type": "virtual"}}}'

n=cmp1-nuc11
kubectl patch node $n -p '{"metadata":{"labels":{"feature.node.kubernetes.io/3dprinter": "prusa-mini" }}}'
kubectl patch node $n -p '{"metadata":{"labels":{"longhorn": "yes"}}}'
kubectl patch node $n -p '{"metadata":{"labels":{"type": "main"}}}'

# nefunguje
# kubectl patch node cmp1-nuc11 -p '{"metadata":{"annotations":{"node.longhorn.io/default-disks-config": "[{"path":"/var/lib/longhorn","allowScheduling": true, "tags":["ssd", "nvme"]}]"}}}'
k edit node $n
node.longhorn.io/default-disks-config: '[{"path":"/var/lib/longhorn","allowScheduling": true, "tags":["nvme", "ssd", "fast"]}]'
node.longhorn.io/default-disks-config: '[{"path":"/var/lib/longhorn","allowScheduling": true, "tags":["hdd", "slow"]}]'

