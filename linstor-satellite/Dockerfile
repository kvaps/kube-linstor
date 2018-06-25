FROM debian:stretch
ENV DEBIAN_FRONTEND noninteractive

# Install repos and system upgrade
RUN apt-get -y update \
 && apt-get install -y wget gnupg \
 && wget -O- https://packages.linbit.com/package-signing-pubkey.asc \
      | apt-key add - \
 && echo "deb http://download.proxmox.com/debian/pve stretch pve-no-subscription" \
      > /etc/apt/sources.list.d/pve-install-repo.list \
 && wget http://download.proxmox.com/debian/proxmox-ve-release-5.x.gpg \
      -O /etc/apt/trusted.gpg.d/proxmox-ve-release-5.x.gpg \
 && echo "deb http://packages.linbit.com/proxmox/ proxmox-5 drbd-9.0" \
      > /etc/apt/sources.list.d/linbit.list \
 && apt-get update \
 && apt-get -y upgrade \
 && apt-get clean
 
# Install linstor-server
RUN apt-get update \
 && apt-get install -y linstor-server \
 && apt-get clean

# Install additional tools
RUN apt-get update \
 && apt-get install -y zfsutils-linux \
 && apt-get clean

WORKDIR "/opt/linstor-server"
ENTRYPOINT [ "/opt/linstor-server/bin/Satellite" ]
