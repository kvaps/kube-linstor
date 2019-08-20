# Kube-Linstor

Containerized Linstor Storage and Operator easy to run in your Kubernetes cluster.

## Images


| Image                    | Build Status                                                                      |
|--------------------------|-----------------------------------------------------------------------------------|
| **[linstor-controller]** | [![linstor-controller-status]](https://hub.docker.com/r/kvaps/linstor-controller) |
| **[linstor-satellite]**  | [![linstor-satellite-status]](https://hub.docker.com/r/kvaps/linstor-satellite)   |
| **[linstor-stunnel]**    | [![linstor-stunnel-status]](https://hub.docker.com/r/kvaps/linstor-stunnel)       |
| **[linstor-operator]**   | [![linstor-operator-status]](https://hub.docker.com/r/kvaps/linstor-operator)     |

[linstor-controller]: dockerfiles/linstor-controller/Dockerfile
[linstor-controller-status]: https://img.shields.io/docker/cloud/build/kvaps/linstor-controller.svg
[linstor-satellite]: dockerfiles/linstor-controller/Dockerfile
[linstor-satellite-status]: https://img.shields.io/docker/cloud/build/kvaps/linstor-satellite.svg
[linstor-stunnel]: dockerfiles/linstor-stunnel/Dockerfile
[linstor-stunnel-status]: https://img.shields.io/docker/cloud/build/kvaps/linstor-stunnel.svg
[linstor-operator]: dockerfiles/linstor-operator/Dockerfile
[linstor-operator-status]: https://img.shields.io/docker/cloud/build/kvaps/linstor-operator.svg

## Requirements

* Working Kubernetes cluster
* DRBD9 kernel module installed on each sattelite node
* PostgeSQL database or other backing store for redundancy

## Limitations

* Containerized Linstor satellites tested only on Ubuntu and Debian systems.

## QuckStart

Linstor consists of several components:

* **Linstor-controller** - Controller is main control point for Linstor, it provides API for clients and communicates with satellites for creating and monitor DRBD-devices.
* **Linstor-satellite** - Satellites run on every node, they listen and perform controller tasks. They operates directly with LVM and ZFS subsystems.
* **Linstor-csi** - CSI driver provides compatibility level for adding Linstor support for Kubernetes

We are also using:

* **Stunnel** - for encrypt all connections between linstor clients and controller
* **Linstor-operator** - for automate ususual tasks, eg. create linstor nodes and storage pools

#### Database

* Template stolon chart, and apply it:

  ```
  helm fetch stable/stolon --untar
  
  helm template stolon \
    --name linstor-db \
    --namespace linstor \
    --set superuserPassword=hackme \
    --set replicationPassword=hackme \
    --set persistence.enabled=true,persistence.size=10G \
    --set keeper.replicaCount=3 \
    --set keeper.nodeSelector.node-role\\.kubernetes\\.io/master= \
    --set keeper.tolerations[0].effect=NoSchedule,keeper.tolerations[0].key=node-role.kubernetes.io/master \
    --set proxy.replicaCount=3 \
    --set proxy.nodeSelector.node-role\\.kubernetes\\.io/master= \
    --set proxy.tolerations[0].effect=NoSchedule,proxy.tolerations[0].key=node-role.kubernetes.io/master \
    --set sentinel.replicaCount=3 \
    --set sentinel.nodeSelector.node-role\\.kubernetes\\.io/master= \
    --set sentinel.tolerations[0].effect=NoSchedule,sentinel.tolerations[0].key=node-role.kubernetes.io/master \
    > linstor-db.yaml
  
  kubectl create -f linstor-db.yaml -n linstor
  ```

  **NOTE:** in case of update your stolon add `--set job.autoCreateCluster=false` flag to not reinitialisate your cluster

* Create Persistent Volumes:
  ```
  cd helm

  helm template pv-hostpath \
    --name data-linstor-db-stolon-keeper-0 \
    --namespace linstor \
    --set node=node1,path=/var/lib/linstor-db \
    > pv1.yaml

  helm template pv-hostpath \
    --name data-linstor-db-stolon-keeper-1 \
    --namespace linstor \
    --set node=node2,path=/var/lib/linstor-db \
    > pv2.yaml

  helm template pv-hostpath \
    --name data-linstor-db-stolon-keeper-2 \
    --namespace linstor \
    --set node=node3,path=/var/lib/linstor-db \
    > pv3.yaml

  kubectl create -f pv1.yaml -f pv2.yaml -f pv3.yaml
  ```

  Parameters `name` and `namespace` **must match** the PVC's name and namespace of your database, `node` should match exact node name.

  Check your PVC/PV list after creation, if everything right, they should obtain **Bound** status.

* Connect to database:
  ```
  kubectl exec -ti -n linstor linstor-db-stolon-keeper-0 bash
  PGPASSWORD=$(cat $STKEEPER_PG_SU_PASSWORDFILE) psql -h linstor-db-stolon-proxy -U stolon postgres
  ```
  
* Create user and database for linstor:
  ```
  CREATE DATABASE linstor;
  CREATE USER linstor WITH PASSWORD 'hackme';
  GRANT ALL PRIVILEGES ON DATABASE linstor TO linstor;
  ```

#### Linstor

* Template kube-linstor chart, and apply it:

  ```
  cd helm

  helm template kube-linstor \
    --namespace linstor \
    --set controller.db.user=linstor \
    --set controller.db.password=hackme \
    --set controller.db.connectionUrl=jdbc:postgresql://linstor-db-stolon-proxy/linstor \
    --set controller.nodeSelector.node-role\\.kubernetes\\.io/master= \
    --set controller.tolerations[0].effect=NoSchedule,controller.tolerations[0].key=node-role.kubernetes.io/master \
    --set satellite.tolerations[0].effect=NoSchedule,satellite.tolerations[0].key=node-role.kubernetes.io/master \
    --set csi.controller.nodeSelector.node-role\\.kubernetes\\.io/master= \
    --set csi.controller.tolerations[0].effect=NoSchedule,csi.controller.tolerations[0].key=node-role.kubernetes.io/master \
    --set csi.node.tolerations[0].effect=NoSchedule,csi.node.tolerations[0].key=node-role.kubernetes.io/master \
    > linstor.yaml

  kubectl create -f linstor.yaml
  ```

## Usage

You can get interactive linstor shell by simple exec into **linstor-controller** container:

```
kubectl exec -ti -n linstor linstor-controller-0 linstor
```

Refer to [official linstor documentation](https://docs.linbit.com/linbit-docs/) for define nodes and create new resources.

## Licenses

* This project under **[Apache License](LICENSE)**
* **[linstor-server]**, **[drbd]** and **[drbd-utils]** is **GPL** licensed by LINBIT

[linstor-server]: https://github.com/LINBIT/linstor-server/blob/master/COPYING
[drbd]: https://github.com/LINBIT/drbd-9.0/blob/master/COPY
[drbd-utils]: https://github.com/LINBIT/drbd-utils/blob/master/COPYING
