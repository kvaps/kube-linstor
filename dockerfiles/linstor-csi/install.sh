#!/bin/sh

set -e

VENDOR=linbit
DRIVER=linstor-flexvolume

# Install driver
driver_dir=$VENDOR${VENDOR:+"~"}${DRIVER}
mkdir -p "/flexmnt/$driver_dir"
cp "/$DRIVER" "/flexmnt/$driver_dir/.$DRIVER"
mv -f "/flexmnt/$driver_dir/.$DRIVER" "/flexmnt/$driver_dir/$DRIVER"

# Update old driver also
for LN_DRIVER in nbd loop sheepdog; do
  ln_driver_dir=$VENDOR${VENDOR:+"~"}${LN_DRIVER}
  mkdir -p "/flexmnt/$ln_driver_dir"
  ln -sf "../$driver_dir/$DRIVER" "/flexmnt/$ln_driver_dir/$LN_DRIVER"
done

# Sleep calm
exec tail -f /dev/null
