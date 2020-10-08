# Perform backups and database management

If you're using stolon as back-end for your LINSTOR installation you can easily perform the backup of your database:
```bash
kubectl exec -n linstor sts/linstor-db-stolon-keeper -- \
  sh -c 'PGPASSWORD=$(cat $STKEEPER_PG_SU_PASSWORDFILE) pg_dump -c -h linstor-db-stolon-proxy -U stolon linstor | gzip' \
  > linstor-backup.sql.gz
```

If you need to restore database from backup:
```bash
kubectl exec -i -n linstor sts/linstor-db-stolon-keeper -- \
  sh -c 'zcat | PGPASSWORD=$(cat $STKEEPER_PG_SU_PASSWORDFILE) psql -h linstor-db-stolon-proxy -U stolon -d linstor' \
  < linstor-backup.sql.gz
```

---

To check the state of stolon cluster do
```bash
kubectl exec -n linstor sts/linstor-db-stolon-keeper -- stolonctl --cluster-name linstor-db-stolon --store-backend kubernetes --kube-resource-kind=configmap status
```
---

If something has gonna wrong, you can always connect to your database to perform manual actions:

```bash
kubectl exec -ti -n linstor sts/linstor-db-stolon-keeper -- \
  sh -c 'PGPASSWORD=$(cat $STKEEPER_PG_SU_PASSWORDFILE) psql -h linstor-db-stolon-proxy -U stolon linstor'
```

Note, if you have different user name unlike `linstor` you need to make schema visible on each connect:
```sql
SET search_path TO "LINSTOR",public;
```
