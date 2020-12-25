# Kube-Linstor

Containerized Linstor Storage easy to run in your Kubernetes cluster.

## Images

| Image                            | Latest Tag                                                                               |
|:---------------------------------|:-----------------------------------------------------------------------------------------|
| **[linstor-controller]**         | [![linstor-controller-version]](https://hub.docker.com/r/kvaps/linstor-controller)       |
| **[linstor-satellite]**          | [![linstor-satellite-version]](https://hub.docker.com/r/kvaps/linstor-satellite)         |
| **[linstor-csi]**                | [![linstor-csi-version]](https://hub.docker.com/r/kvaps/linstor-csi)                     |
| **[linstor-stork]**              | [![linstor-stork-version]](https://hub.docker.com/r/kvaps/linstor-stork)                 |
| **[linstor-ha-controller]**      | [![linstor-ha-controller-version]](https://hub.docker.com/r/kvaps/linstor-ha-controller) |

[linstor-controller]: dockerfiles/linstor-controller/Dockerfile
[linstor-controller-version]: https://img.shields.io/docker/v/kvaps/linstor-controller.svg?sort=semver
[linstor-satellite]: dockerfiles/linstor-controller/Dockerfile
[linstor-satellite-version]: https://img.shields.io/docker/v/kvaps/linstor-satellite.svg?sort=semver
[linstor-csi]: dockerfiles/linstor-csi/Dockerfile
[linstor-csi-version]: https://img.shields.io/docker/v/kvaps/linstor-csi.svg?sort=semver
[linstor-stork]: dockerfiles/linstor-stork/Dockerfile
[linstor-stork-version]: https://img.shields.io/docker/v/kvaps/linstor-stork.svg?sort=semver
[linstor-ha-controller]: dockerfiles/linstor-ha-controller/Dockerfile
[linstor-ha-controller-version]: https://img.shields.io/docker/v/kvaps/linstor-ha-controller.svg?sort=semver

## Requirements

* Working Kubernetes cluster (`v1.17` or higher).
* DRBD9 kernel module installed on each satellite node.
* PostgeSQL database / etcd or any other backing store for redundancy.
* [Snapshot Controller](https://kubernetes-csi.github.io/docs/snapshot-controller.html#snapshot-controller) (optional)

## QuckStart

Kube-Linstor consists of several components:

* **Linstor-controller** - Controller is the main control point for Linstor. It provides an API for clients and communicates with satellites for creating and monitoring DRBD-devices.
* **Linstor-satellite** - Satellites run on every node. They listen and perform controller tasks, and operate directly with LVM and ZFS subsystems.
* **Linstor-csi** - CSI driver provides compatibility level for adding Linstor support for Kubernetes.
* **Linstor-stork** - Stork is a scheduler extender plugin for Kubernetes which allows a storage driver to give the Kubernetes scheduler hints about where to place a new pod so that it is optimally located for storage performance.

#### Preparation

[Install Helm](https://helm.sh/docs/intro/).

> **_NOTE:_**
> Commands below provided for Helm v3 but Helm v2 is also supported.  
> You can use `helm template` instead of `helm install`, this is also working as well.

Create `linstor` namespace.
```
kubectl create ns linstor
```

Install Helm repository:
```
helm repo add kvaps https://kvaps.github.io/charts
```

#### Database

* Install [stolon](https://github.com/kvaps/stolon-chart) chart:

  ```bash
  # download example values
  curl -LO https://github.com/kvaps/kube-linstor/raw/v1.11.0/examples/linstor-db.yaml

  # install release
  helm install linstor-db kvaps/stolon \
    --namespace linstor \
    -f linstor-db.yaml
  ```

  > **_NOTE:_**
  > The current example will deploy stolon cluster on your Kubernetes-master nodes

  > **_NOTE:_**
  > In case of update your stolon add `--set job.autoCreateCluster=false` flag to not reinitialisate your cluster.

* Create Persistent Volumes:
  ```bash
  helm install data-linstor-db-stolon-keeper-0 kvaps/pv-hostpath \
    --namespace linstor \
    --set path=/var/lib/linstor-db \
    --set node=node1

  helm install data-linstor-db-stolon-keeper-1 kvaps/pv-hostpath \
    --namespace linstor \
    --set path=/var/lib/linstor-db \
    --set node=node2

  helm install data-linstor-db-stolon-keeper-2 kvaps/pv-hostpath \
    --namespace linstor \
    --set path=/var/lib/linstor-db \
    --set node=node3
  ```

  Parameters `name` and `namespace` **must match** the PVC's name and namespace of your database, `node` should match exact node name.

  Check your PVC/PV list after creation, if everything right, they should obtain **Bound** status.

* Connect to database:
  ```bash
  kubectl exec -ti -n linstor sts/linstor-db-stolon-keeper -- bash
  PGPASSWORD=$(cat $STKEEPER_PG_SU_PASSWORDFILE) psql -h linstor-db-stolon-proxy -U stolon postgres
  ```

* Create user and database for linstor:
  ```bash
  CREATE DATABASE linstor;
  CREATE USER linstor WITH PASSWORD 'hackme';
  GRANT ALL PRIVILEGES ON DATABASE linstor TO linstor;
  ```

#### Linstor

* Install kube-linstor chart:

  ```bash
  # download example values
  curl -LO https://github.com/kvaps/kube-linstor/raw/v1.11.0/examples/linstor.yaml

  # install release
  helm install linstor kvaps/linstor --version 1.11.0 \
    --namespace linstor \
    -f linstor.yaml
  ```

  > **_NOTE:_**
  > The current example will deploy linstor- and csi-controllers on your Kubernetes-master nodes and satellites on all nodes in the cluster.


## Install snapshot-controller

https://kubernetes-csi.github.io/docs/snapshot-controller.html#deployment

## Usage

You can get interactive linstor shell by simple exec into **linstor-controller** container:

```bash
kubectl exec -ti -n linstor deploy/linstor-controller -- linstor
```

Refer to [official linstor documentation](https://docs.linbit.com/linbit-docs/) to define nodes and create new resources.

#### SSL notes

This chart enables SSL encryption for control-plane by default. It does not affect the DRBD performance but makes your LINSTOR setup more secure.

Any way, do not forget to specify `--communicates-type SSL` option during node creation, example:

```bash
linstor node create alpha 1.2.3.4 --communication-type SSL
```

If you want to have external access, you need to download certificates for linstor client:

```bash
kubectl get secrets --namespace linstor linstor-client-tls \
  -o go-template='{{ range $k, $v := .data }}{{ $v | base64decode }}{{ end }}'
```

Then follow [official linstor documentation](https://www.linbit.com/drbd-user-guide/users-guide-linstor/#s-rest-api-https-restricted-client) to configure the client.

> **_NOTE:_**
> v1.9.0 release also introduce shorter release name: `linstor-` instead of `linstor-linstor-`, this change shouldn't break anything, however it will regenerate SSL certificates.
If you are using LINSTOR API externally, you might need to update the client certificates or keep the old release name prefix by specifying `--set fullnameOverride=linstor-linstor` option.
>
> See [#18](https://github.com/kvaps/kube-linstor/issues/18) for more details.

## Additional Information

* [Perform backups and database management](docs/BACKUP.md)
* [Upgrade notes](docs/UPGRADE.md)

## Licenses

* **[This project](LICENSE)** under **Apache License**
* **[linstor-server]**, **[drbd]** and **[drbd-utils]** is **GPL** licensed by LINBIT
* **[linstor-csi]** under **Apache License** by LINBIT
* **[stork]** under **Apache License**

[linstor-server]: https://github.com/LINBIT/linstor-server/blob/master/COPYING
[drbd]: https://github.com/LINBIT/drbd-9.0/blob/master/COPY
[drbd-utils]: https://github.com/LINBIT/drbd-utils/blob/master/COPYING
[linstor-csi]: https://github.com/piraeusdatastore/linstor-csi/blob/master/LICENSE
[stork]: https://github.com/libopenstorage/stork/blob/master/LICENSE
