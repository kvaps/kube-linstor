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


#### Preparation

[Install Helm](https://helm.sh/docs/intro/) and clone this repository, then cd into it.

> **_NOTE:_**  
> Commands below provided for Helm v3 but Helm v2 is also supported.  
> You can use `helm template` instead of `helm install`, this is also working as well.

#### Database

* Install [stolon](https://github.com/helm/charts/tree/master/stable/stolon) chart:

  ```
  helm repo add stable https://kubernetes-charts.storage.googleapis.com
  helm install linstor-db stable/stolon -f examples/linstor-db.yaml
  ```

  > **_NOTE:_**  
  > In case of update your stolon add `--set job.autoCreateCluster=false` flag to not reinitialisate your cluster

* Create Persistent Volumes:
  ```
  helm install \
    --set node=node1,path=/var/lib/linstor-db \
    data-linstor-db-stolon-keeper-0 \
    helm/pv-hostpath

  helm install \
    --set node=node2,path=/var/lib/linstor-db \
    data-linstor-db-stolon-keeper-1 \
    helm/pv-hostpath

  helm install \
    --set node=node3,path=/var/lib/linstor-db \
    data-linstor-db-stolon-keeper-2 \
    helm/pv-hostpath
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

* Install kube-linstor chart:

  ```
  helm install -g helm/kube-linstor --namespace linstor -f examples/linstor-db.yaml
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
