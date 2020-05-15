# Better to use fresh distros since they are containing newer lvm

FROM debian:buster as builder
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install build-essential git default-jdk-headless dh-systemd gradle python3-all

ARG VERSION=1.7.1

RUN git clone https://github.com/LINBIT/linstor-server.git /linstor-server
WORKDIR /linstor-server
RUN git checkout v${VERSION}

RUN make debrelease \
 && mv linstor-server-${VERSION}.tar.gz /linstor-server_${VERSION}.orig.tar.gz \
 && tar -C / -xvf /linstor-server_${VERSION}.orig.tar.gz

WORKDIR /linstor-server-${VERSION}
RUN dpkg-buildpackage -us -uc

FROM debian:buster
ENV DEBIAN_FRONTEND noninteractive

# Install repos and system upgrade
RUN apt-get -y update \
 && apt-get -y upgrade \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install linstor-satellite
COPY --from=builder /linstor-common_*_all.deb /linstor-satellite_*_all.deb /packages/
RUN apt-get update \
 && apt-get install -y default-jre-headless drbd-utils thin-provisioning-tools \
 && dpkg -i packages/*.deb \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /config /logs

# Install additional tools
RUN sed -i '/^deb / s/main/main contrib/' /etc/apt/sources.list \
 && apt-get update \
 && apt-get install --no-install-recommends -y zfsutils-linux cryptsetup nvme-cli \
 && apt-get download lvm2 \
 && dpkg --unpack lvm2*.deb \
 && rm -f lvm2*.deb /var/lib/dpkg/info/lvm2.postinst \
 && apt-get -fy install \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && sed -i /etc/lvm/lvm.conf \
      -e "s%#\? \?\(use_lvmetad *=\).*%\1 0%" \
      -e "s%#\? \?\(error_when_full *=\).*%\1 1%" \
      -e "s%#\? \?\(global_filter *=\).*%\1 [ \"r|/dev/drbd.*|\", \"r|/dev/dm-.*|\", \"r|/dev/zd.*|\" ]%"

ENTRYPOINT [ "/usr/share/linstor-server/bin/Satellite", "--logs=/logs", "--config-directory=/config" ]
