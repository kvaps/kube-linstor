

# Satelite-node (init-container)
docker run --net=host --rm \
    -v /etc/:/host-etc \
    kvaps/linstor-satellite sh -c '
      mkdir -p /host-etc/drbd.d
      cp -f /etc/drbd.conf /host-etc/drbd.conf
      cp -f /etc/drbd.d/global_common.conf \
        /host-etc/drbd.d/global_common.conf'

# Satelite-node
docker run --net=host --rm -d --name=linstor-satellite --privileged \
    -v /etc/drbd.conf:/etc/drbd.conf:rw \
    -v /lib/modules:/lib/modules \
    -v /var/lib/drbd.d:/var/lib/drbd.d \
    -v /etc/drbd.d:/etc/drbd.d \
    -v /var/lib/drbd:/var/lib/drbd \
    -v /dev:/dev \
    kvaps/linstor-satellite

# Controller-node
docker run --net=host --rm -d --name=linstor-controller \
    -v ${PWD}:/data \
    kvaps/linstor-controller

# Client
docker run --net=host --rm -ti kvaps/linstor-client
