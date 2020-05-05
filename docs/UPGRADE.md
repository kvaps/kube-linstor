# Upgrade notes


If you're using stolon as back-end for your LINSTOR installation you can easily perform the backup of your database:
   
```bash
kubectl exec -n linstor linstor-db-stolon-keeper-0 -- \
  sh -c 'PGPASSWORD=$(cat $STKEEPER_PG_SU_PASSWORDFILE) pg_dump -c -h linstor-db-stolon-proxy -U stolon linstor | gzip' \
  > linstor-backup.sql.gz
```

It always recommended to perform the backup before each LINSTOR upgrade.



Also if you were using `helm template` to perform the installation as described in [README.md for v1.1.2](https://github.com/kvaps/kube-linstor/tree/v1.1.2), I would suggest you switch to Helmv3, however helm template method should also work fine, we're using it with [qbec](https://qbec.io/).
   
Anyway you can perform upgrade by simple replacing resources in your Kubernetes cluster thus
   
---

## Upgrading stolon


***Helm way:***

  ```bash
  helm upgrade linstor-db stable/stolon --namespace linstor -f examples/linstor-db.yaml
  ```

***Templated manifests:***

  - (optional) Remove all stolon resources except generated ones.  
    The generated resources (like PVC's and `stolon-cluster-linstor-db-stolon` configmap), should remain in the cluster even after you remove mentioned statefulsets for them.

  - Install new resources with the same names, they should start using old PVCs and `linstor-db-stolon` configmap to reload cluster state. Specify `--set job.autoCreateCluster=false` option for stolon chart.

## Upgrading LINSTOR


***Helm way:***

  ```bash
  git pull # download latest changes
  helm upgrade linstor helm/kube-linstor --namespace linstor -f examples/linstor.yaml
  ```

***Templated manifests:***

 - (optional) Remove all LINSTOR resources, it does not store any state in the Kubernetes cluster, so you can do that without fear. The LINSTOR state is stored only in database.

 - Create new LINSTOR resources. check the controller log, it should perform the schema migration for the database.


If you're upgrading from old version you can see your nodes in `Offline` state, that's because latest version enables mutual ssl authentification for the linstor-satellites.

You can easily fix that by executing this command in your linstor-controller pod:
```bash
linstor n l | awk '/(PLAIN)/ { print "linstor n i m -p 3367 --communication-type SSL " $2 " default" }' | sh -ex
```
