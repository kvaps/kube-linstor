FROM ubuntu:xenial
ENV DEBIAN_FRONTEND noninteractive

# Install repos and system upgrade
RUN apt-get -y update \
 && apt-get install -y wget gnupg \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC1B5A793C04BB3905AD837734893610CEAA9512 \
 && echo "deb http://ppa.launchpad.net/linbit/linbit-drbd9-stack/ubuntu xenial main" \
      > /etc/apt/sources.list.d/linbit.list \
 && apt-get update \
 && apt-get -y upgrade \
 && apt-get clean

# Install tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]
 
# Install linstor-satellite
RUN apt-get update \
 && apt-get install -y linstor-satellite drbd-utils \
 && mkdir -p /config /logs \
 && apt-get clean

# Install additional tools
RUN apt-get update \
 && apt-get install -y kmod zfsutils-linux \
 && apt-get download lvm2 \
 && dpkg --unpack lvm2*.deb \
 && rm -f lvm2*.deb /var/lib/dpkg/info/lvm2.postinst \
 && apt-get -fy install \
 && apt-get clean \
 && sed -i 's/\(use_lvmetad\|udev_sync\|udev_rules\) = 1/\1 = 0/' /etc/lvm/lvm.conf

CMD [ "/usr/share/linstor-server/bin/Satellite", "--logs=/logs", "--config-directory=/config" ]
