# Linstor Storage in containers

Docker images for run containerized linstor storage cluster in your kubernetes cluster.

## Images


| Image                    | Build Status                 | Description                                      |
|--------------------------|------------------------------|--------------------------------------------------|
| **[linstor-controller]** | ![linstor-controller-status] | linstor-controller daemon with prostgres backend |
| **[linstor-satellite]**  | ![linstor-satellite-status]  | linstor-satellite daemon with drbd/zfs/lvm tools |
| **[linstor-client]**     | ![linstor-client-status]     | linstor-client binaries and drbdtop              |

[linstor-controller]: linstor-controller/Dockerfile
[linstor-controller-status]: https://img.shields.io/docker/build/kvaps/linstor-controller.svg
[linstor-satellite]: linstor-controller/Dockerfile
[linstor-satellite-status]: https://img.shields.io/docker/build/kvaps/linstor-satellite.svg
[linstor-client]: linstor-controller/Dockerfile
[linstor-client-status]: https://img.shields.io/docker/build/kvaps/linstor-client.svg

## Requirements

* Working Kubernetes cluster
* DRBD9 kernel module installed on each sattelite node
* PostgeSQL database or other backing store for redundancy

## QuckStart

### Simple run

You can test linstor without k8s cluster, check [docker.sh](examples/docker.sh) for more info.

### Controller daemon

#### Simple solution with backing store

If you already have fault-tolerant storage, you can use it as a backend for linstor-controller's database, which will saved inside the linstor-controller daemon's container.

* This example will deploy **linstor-controller** with local database:

  ```bash
  kubectl create -f examples/linstor-controller.yaml
  ```

#### Complex solution with PostgreSQL database

Here we will use [stolon](https://github.com/sorintlab/stolon) and [local-volumes](https://kubernetes.io/blog/2018/04/13/local-persistent-volumes-beta/) feature for create fault-tollerance PostgreSQL database.

* First we should add role and role binding:
  ```bash
  kubectl apply -f https://raw.githubusercontent.com/sorintlab/stolon/master/examples/kubernetes/role.yaml
  kubectl apply -f https://raw.githubusercontent.com/sorintlab/stolon/master/examples/kubernetes/role-binding.yaml
  ```

* Initialize cluster (Generate specific configmap for stolon)
  ```
  kubectl run -i -t stolonctl --image=sorintlab/stolon:master-pg9.6 --restart=Never --rm -- /usr/local/bin/stolonctl --cluster-name=linstordb --store-backend=kubernetes --kube-resource-kind=configmap init
  ```

* Then we need to create **local volumes** for **stolon-keeper** daemons.</br>
  Let's assume that we going to use this three nodes for linstor database: `node1`, `node2` and `node3`.</br>
  Each one should have created `/data/k8s/linstordb` directory for store postgres data.

* Then we should define this directories as persitentVolumes in our kubernetes cluster:

  ```bash
  ID=1 NODE=node1 envsubst < examples/linstordb-volume.tpl | kubectl create -f-
  ID=2 NODE=node2 envsubst < examples/linstordb-volume.tpl | kubectl create -f-
  ID=3 NODE=node3 envsubst < examples/linstordb-volume.tpl | kubectl create -f-
  ```

* Now we can create database daemons:

  ```bash
  kubectl create -f examples/database/
  ```
* And database itself:

  ```bash
  kubectl run -i -t psql --image=sorintlab/stolon:master-pg9.6 --restart=Never --env=PGPASSWORD=linstor --rm /usr/bin/psql -- --host linstordb --port 5432 postgres -U linstor -c 'CREATE DATABASE linstor;'
  ```
* Now we ready for deploy **linstor-container**:

  ```bash
  kubectl create -f examples/linstor-cotroller-psql.yaml
  ```

### Satellite daemons

* Before continue, please ensure that you have installed **drbd9** kernel module on each satellite node.

* Apply linstor satellite daemonset:

  ```bash
  kubectl create -f examples/linstor-satellite.yaml
  ```

* Then label wanted nodes for run this daemonset:
  ```
  kubectl label node node{1..10} linstor-satellite=
  ```

### Usage

* You can access to linstor console from **linstor-controller** container, or run new **linstor-client** for this purpose:

  ```bash
  kubectl run -i -t linstor-client --image=kvaps/linstor-client --restart=Never --env=LS_CONTROLLERS=linstor-controller --rm /bin/bash
  ```
* Then read [linstor documentation](https://docs.linbit.com/docs/users-guide-9.0/#_common_administrative_tasks_linstor) for define nodes and new resources.

## Licenses

* This **docker images** and **manifests** under **[Apache License](LICENSE)**
* **[linstor-server]**, **[drbd]** and **[drbd-utils]** is **GPL** licensed by LINBIT

[linstor-server]: https://github.com/LINBIT/linstor-server/blob/master/COPYING
[drbd]: https://github.com/LINBIT/drbd-9.0/blob/master/COPY
[drbd-utils]: https://github.com/LINBIT/drbd-utils/blob/master/COPYING
