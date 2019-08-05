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


#### Initial steps

* Create linstor namespace:

  ```
  kubectl create namespace linstor
  ```

* Initiate stunnel config:

  ```
  echo 'linstor:LongAndSecureKeyHere1234512345' > psk.txt
  kubectl create secret generic --from-file psk.txt linstor-stunnel -n linstor
  kubectl create secret generic --from-file psk.txt linstor-stunnel -n kube-system
  kubectl create -f examples/linstor-stunnel.yaml -n linstor
  kubectl create -f examples/linstor-stunnel.yaml -n kube-system
  ```

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

* Create Persistent Volumes:
  ```
  ID=0 NODE=node1 envsubst < examples/linstor-db-volume.tpl | kubectl create -f -
  ID=1 NODE=node2 envsubst < examples/linstor-db-volume.tpl | kubectl create -f -
  ID=2 NODE=node3 envsubst < examples/linstor-db-volume.tpl | kubectl create -f -
  ```

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

#### Linstor Controller

* Save credentials into secret:
  ```
  cat > linstor.toml <<\EOT
  [db]
    user = "linstor"
    password = "hackme"
    connection_url = "jdbc:postgresql://linstor-db-stolon-proxy/linstor"
  EOT
  
  kubectl create secret generic --from-file linstor.toml linstor-controller -n linstor
  ```
  
* Apply Linstor Controller manifest:
  ```
  kubectl apply -f examples/linstor-controller.yaml -n linstor
  ```

#### Linstor Satellites

* Apply Linstor Satellite manifest:

  ```
  kubectl apply -f examples/linstor-satellite.yaml -n linstor
  ```

#### Linstor CSI Driver

* Apply Linstor CSI manifest:

  ```
  kubectl apply -f examples/linstor-csi.yaml -n kube-system
  ```

  You can find examples for creating StorageClass and PVC in [official linstor-csi repo](https://github.com/LINBIT/linstor-csi/tree/master/examples/k8s)

#### Linstor Operator (optional)

* Apply Linstor Operator manifest:

  ```
  kubectl apply -f examples/linstor-operator.yaml -n linstor
  kubectl apply -f examples/linstor-crd.yaml
  ```
  
  You can find examples for creating LinstorController, LinstorNodes and LinstorStoragePools in [examples/linstor-operator-cr.yaml](examples/linstor-operator-cr.yaml)

## Usage

You can get interactive linstor shell by simple exec into **linstor-controller** container:

```
kubectl exec -ti -n linstor linstor-controller-0 linstor
```

Refer to [official linstor documentation](https://docs.linbit.com/linbit-docs/) for define nodes and create new resources.

## Licenses

* This **docker images** and **manifests** under **[Apache License](LICENSE)**
* **[linstor-server]**, **[drbd]** and **[drbd-utils]** is **GPL** licensed by LINBIT

[linstor-server]: https://github.com/LINBIT/linstor-server/blob/master/COPYING
[drbd]: https://github.com/LINBIT/drbd-9.0/blob/master/COPY
[drbd-utils]: https://github.com/LINBIT/drbd-utils/blob/master/COPYING
