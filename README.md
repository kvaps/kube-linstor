# Kube-Linstor

Containerized Linstor Storage easy to run in your Kubernetes cluster.

## Images


| Image                    | Build Status                                                                      |
|:-------------------------|:----------------------------------------------------------------------------------|
| **[linstor-controller]** | [![linstor-controller-status]](https://hub.docker.com/r/kvaps/linstor-controller) |
| **[linstor-satellite]**  | [![linstor-satellite-status]](https://hub.docker.com/r/kvaps/linstor-satellite)   |
| **[linstor-csi]**        | [![linstor-csi-status]](https://hub.docker.com/r/kvaps/linstor-csi)               |
| **[linstor-stork]**      | [![linstor-stork-status]](https://hub.docker.com/r/kvaps/linstor-stork)           |

[linstor-controller]: dockerfiles/linstor-controller/Dockerfile
[linstor-controller-status]: https://img.shields.io/docker/v/kvaps/linstor-controller.svg?sort=semver
[linstor-satellite]: dockerfiles/linstor-controller/Dockerfile
[linstor-satellite-status]: https://img.shields.io/docker/v/kvaps/linstor-satellite.svg?sort=semver
[linstor-csi]: dockerfiles/linstor-csi/Dockerfile
[linstor-csi-status]: https://img.shields.io/docker/v/kvaps/linstor-csi.svg?sort=semver
[linstor-stork]: dockerfiles/linstor-stork/Dockerfile
[linstor-stork-status]: https://img.shields.io/docker/v/kvaps/linstor-stork.svg?sort=semver

## Requirements

* Working Kubernetes cluster (`v1.17` or higher).
* DRBD9 kernel module installed on each satellite node.
* PostgeSQL database / etcd or any other backing store for redundancy.

## QuckStart

Kube-Linstor consists of several components:

* **Linstor-controller** - Controller is main control point for Linstor, it provides API for clients and communicates with satellites for creating and monitor DRBD-devices.
* **Linstor-satellite** - Satellites run on every node, they listen and perform controller tasks. They operates directly with LVM and ZFS subsystems.
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
  curl -LO https://github.com/kvaps/kube-linstor/raw/master/examples/linstor-db.yaml

  # install release
  helm install linstor-db kvaps/stolon \
    --namespace linstor \
    -f linstor-db.yaml
  ```

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
  kubectl exec -ti -n linstor linstor-db-stolon-keeper-0 bash
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
  curl -LO https://github.com/kvaps/kube-linstor/raw/master/examples/linstor.yaml

  # install release
  helm install linstor kvaps/linstor --version 1.9.0 \
    --namespace linstor \
    -f linstor.yaml
  ```

## Usage

You can get interactive linstor shell by simple exec into **linstor-controller** container:

```bash
kubectl exec -ti -n linstor linstor-linstor-controller-0 -- linstor
```

Refer to [official linstor documentation](https://docs.linbit.com/linbit-docs/) for define nodes and create new resources.

#### SSL notes

This chart enables SSL encryption for control-plane by default. It does not affect the DRBD performance but makes your LINSTOR setup more secure.

Any way, do not forget to specify `--communicates-type SSL` option during node creation, example:

```bash
linstor node create alpha 1.2.3.4 --communication-type SSL
```

If you want to have external access, you need to download certificates for linstor client:

```bash
kubectl get secrets --namespace linstor linstor-linstor-client-tls \
  -o go-template='{{ range $k, $v := .data }}{{ $v | base64decode }}{{ end }}'
```

Then follow [official linstor documentation](https://www.linbit.com/drbd-user-guide/users-guide-linstor/#s-rest-api-https-restricted-client) to configure client.

#### Enable SSL for existing nodes

If you're switching your setup from PLAIN to SSL, this simple command will reconfigure all your nodes:

```bash
linstor n l | awk '/(PLAIN)/ { print "linstor n i m -p 3367 --communication-type SSL " $2 " default" }' | sh -ex
```

## Additional Information

* [Perform backups and database management](docs/BACKUP.md)
* [Upgrade notes](docs/UPGRADE.md)

## Licenses

* **[This project](LICENSE)** under **Apache License**
* **[linstor-server]**, **[drbd]** and **[drbd-utils]** is **GPL** licensed by LINBIT
* **[stunnel]** under **GNU GPL version 2** by Michał Trojnara
* **[linstor-csi]** under **Apache License** by LINBIT
* **[stork]** under **Apache License**

[linstor-server]: https://github.com/LINBIT/linstor-server/blob/master/COPYING
[drbd]: https://github.com/LINBIT/drbd-9.0/blob/master/COPY
[drbd-utils]: https://github.com/LINBIT/drbd-utils/blob/master/COPYING
[stunnel]: https://www.stunnel.org/COPYING.html
[linstor-csi]: https://github.com/piraeusdatastore/linstor-csi/blob/master/LICENSE
[stork]: https://github.com/libopenstorage/stork/blob/master/LICENSE
