FROM debian:stretch
ENV DEBIAN_FRONTEND noninteractive


RUN apt-get -y update \
 && apt-get install -y wget gnupg \
 && wget -O- https://packages.linbit.com/package-signing-pubkey.asc | apt-key add - \
 && echo "deb http://packages.linbit.com/proxmox/ proxmox-5 drbd-9.0" > \
      /etc/apt/sources.list.d/linbit.list \
 && apt-get update \
 && apt-get install -y linstor-server

WORKDIR "/opt/linstor-server"
ENTRYPOINT [ "/opt/linstor-server/bin/Controller" ]
