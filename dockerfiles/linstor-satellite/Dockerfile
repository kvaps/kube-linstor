FROM debian:buster as builder

ARG VERSION=1.11.0

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install build-essential git default-jdk-headless dh-systemd gradle python3-all

RUN git clone https://github.com/LINBIT/linstor-server.git /linstor-server
WORKDIR /linstor-server
RUN git checkout v${VERSION}

RUN make debrelease \
 && mv linstor-server-${VERSION}.tar.gz /linstor-server_${VERSION}.orig.tar.gz \
 && tar -C / -xvf /linstor-server_${VERSION}.orig.tar.gz

WORKDIR /linstor-server-${VERSION}
RUN dpkg-buildpackage -us -uc

# ------------------------------------------------------------------------------

FROM debian:buster as utils-builder

ARG UTILS_VERSION=9.15.0

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install build-essential debhelper git flex clitest xsltproc locales libxml2-utils po4a bash-completion dh-systemd docbook-xsl udev

RUN git clone --recurse-submodules https://github.com/LINBIT/drbd-utils /drbd-utils
WORKDIR /drbd-utils
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN git checkout v${UTILS_VERSION} \
 && ./autogen.sh \
 && ./configure \
 && make debrelease \
 && mv drbd-utils-${UTILS_VERSION}.tar.gz ../drbd-utils_${UTILS_VERSION}.orig.tar.gz \
 && tar -C / -xvf ../drbd-utils_${UTILS_VERSION}.orig.tar.gz
WORKDIR /drbd-utils-${UTILS_VERSION}
RUN dpkg-buildpackage -us -uc

ARG THIN_SEND_RECV_VERSION=0.24
RUN git clone --recurse-submodules https://github.com/LINBIT/thin-send-recv /thin-send-recv
WORKDIR /thin-send-recv
RUN git checkout v${THIN_SEND_RECV_VERSION} \
 && make debrelease \
 && mv thin-send-recv-${THIN_SEND_RECV_VERSION}.tar.gz ../thin-send-recv_${THIN_SEND_RECV_VERSION}.orig.tar.gz \
 && tar -C / -xvf ../thin-send-recv_${THIN_SEND_RECV_VERSION}.orig.tar.gz
WORKDIR /thin-send-recv-${THIN_SEND_RECV_VERSION}
RUN dpkg-buildpackage -us -uc

# ------------------------------------------------------------------------------

FROM debian:buster

COPY --from=builder /linstor-common_*_all.deb /linstor-satellite_*_all.deb /packages/
COPY --from=utils-builder /python-linstor_*_all.deb /drbd-utils_*_amd64.deb /thin-send-recv_*_amd64.deb /packages/

# Install repos and system upgrade
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update \
 && apt-get -y upgrade \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install linstor-satellite
RUN apt-get update \
 && apt-get install -y default-jre-headless thin-provisioning-tools \
 && dpkg -i packages/*.deb \
 && sed -i "s|'$| \"-Djdk.tls.acknowledgeCloseNotify=true\"'|" \
      /usr/share/linstor-server/bin/Satellite \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /config /logs

# Install additional tools
RUN sed -i '/^deb / s/main/main contrib/' /etc/apt/sources.list \
 && apt-get update \
 && apt-get install --no-install-recommends -y zfsutils-linux cryptsetup nvme-cli zstd socat \
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
