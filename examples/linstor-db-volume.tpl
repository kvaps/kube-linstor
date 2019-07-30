apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-linstor-db-stolon-keeper-${ID}
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /var/lib/linstor-db
    type: DirectoryOrCreate
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: data-linstor-db-stolon-keeper-${ID}
    namespace: linstor
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - ${NODE}
