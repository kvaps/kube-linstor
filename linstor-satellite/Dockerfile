FROM debian:stretch
ENV DEBIAN_FRONTEND noninteractive

# Install repos and system upgrade
RUN apt-get -y update \
 && apt-get install -y wget gnupg \
 && wget -O- https://packages.linbit.com/package-signing-pubkey.asc \
      | apt-key add - \
 && echo "deb http://packages.linbit.com/proxmox/ proxmox-5 drbd-9.0" \
      > /etc/apt/sources.list.d/linbit.list \
 && wget http://download.proxmox.com/debian/proxmox-ve-release-5.x.gpg \
      -O /etc/apt/trusted.gpg.d/proxmox-ve-release-5.x.gpg \
 && echo "deb http://download.proxmox.com/debian/pve stretch pve-no-subscription" \
      > /etc/apt/sources.list.d/pve-install-repo.list \
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
 && apt-get install -y linstor-satellite \
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
 && sed -i 's/\(udev_sync\|udev_rules\) = 1/\1 = 0/' /etc/lvm/lvm.conf

CMD [ "/usr/share/linstor-server/bin/Satellite", "--logs=/logs", "--config-directory=/config" ]
