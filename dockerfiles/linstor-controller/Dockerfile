# We forced to use xenial due OpenJDK 8
# See: https://github.com/LINBIT/linstor-server/issues/123

FROM ubuntu:xenial as builder
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install build-essential git default-jdk-headless dh-systemd gradle python3-all

ARG VERSION=1.7.0

RUN git clone https://github.com/LINBIT/linstor-server.git /linstor-server
WORKDIR /linstor-server
RUN git checkout v${VERSION}

RUN make debrelease \
 && mv linstor-server-${VERSION}.tar.gz /linstor-server_${VERSION}.orig.tar.gz \
 && tar -C / -xvf /linstor-server_${VERSION}.orig.tar.gz

WORKDIR /linstor-server-${VERSION}
RUN dpkg-buildpackage -us -uc

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
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install linstor-controller
COPY --from=builder /linstor-common_*_all.deb /linstor-controller_*_all.deb /packages/
RUN apt-get update \
 && apt-get install -y default-jre-headless linstor-client \
 && dpkg -i packages/linstor-*.deb \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /config /logs \
 && /usr/share/linstor-server/bin/linstor-config create-db-file \
      /data/linstordb > /config/linstor.toml

ENTRYPOINT [ "/usr/share/linstor-server/bin/Controller", "--logs=/logs", "--config-directory=/config" ]
