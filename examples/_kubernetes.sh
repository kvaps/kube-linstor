# Stolon
# https://github.com/sorintlab/stolon

# Stolon role and role binding
kubectl apply -f https://raw.githubusercontent.com/sorintlab/stolon/master/examples/kubernetes/role.yaml
kubectl apply -f https://raw.githubusercontent.com/sorintlab/stolon/master/examples/kubernetes/role-binding.yaml

# Generate stolon configmap
kubectl run -i -t stolonctl --image=sorintlab/stolon:master-pg9.6 --restart=Never --rm -- /usr/local/bin/stolonctl --cluster-name=linstordb --store-backend=kubernetes --kube-resource-kind=configmap init

# Create local persistent volumes
# https://kubernetes.io/docs/concepts/storage/volumes/#local
ID=1 NODE=node1 envsubst < local-volume.yaml.tpl | kubectl create -f-
ID=2 NODE=node2 envsubst < local-volume.yaml.tpl | kubectl create -f-
ID=3 NODE=node3 envsubst < local-volume.yaml.tpl | kubectl create -f-

# Create dirs on nodes
ssh node1 mkdir -p /data/k8s/linstordb
ssh node2 mkdir -p /data/k8s/linstordb
ssh node3 mkdir -p /data/k8s/linstordb

# Create stolon resources
kubectl create -f database/

# Create linstor database
kubectl run -i -t psql --image=sorintlab/stolon:master-pg9.6 --restart=Never --env=PGPASSWORD=linstor --rm /usr/bin/psql -- --host linstordb --port 5432 postgres -U linstor -c 'CREATE DATABASE linstor;'

# Label satellite nodes
kubectl label node node{1..4} linstor-satellite=

# Create Satellites
kubectl create -f linstor-satellite.yaml

# Create Controller
kubectl create -f linstor-cotroller.yaml

# Run client
kubectl run -i -t linstor-client --image=kvaps/linstor-client --restart=Never --env=LS_CONTROLLERS=linstor-controller --rm /bin/bash
