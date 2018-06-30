apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-linstordb-keeper-${ID}
  namespace: default
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /data/k8s/linstordb
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: data-linstordb-keeper-${ID}
    namespace: default
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - ${NODE}
