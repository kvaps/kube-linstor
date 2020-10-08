#!/bin/sh
EC=0

version=$1
[ -z "$version" ] && echo "version is not specified as first argument" && exit 1

echo "bumping version to $version"

sed -i "s/raw\/v[0-9]\+\.[0-9]\+\.[0-9]\+/raw\/v${version}/" README.md

for f in README.md docs/UPGRADE.md; do
  sed -i "s/\(linstor --version\) [0-9]\+\.[0-9]\+\.[0-9]\+/\1 ${version}/" "$f"
  git diff --exit-code "$f" && echo "$f not changed" && EC=1
done

f=helm/kube-linstor/Chart.yaml
sed -i "s/\(^version\|appVersion:\) [0-9]\+\.[0-9]\+\.[0-9]\+/\1 ${version}/" "$f"
git diff --exit-code "$f" && echo "$f not changed" && EC=1

if [ "$EC" != 0 ]; then
  echo
  echo "not all files were changed!"
fi
exit "$EC"
