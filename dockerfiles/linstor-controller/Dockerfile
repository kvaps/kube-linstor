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

# ------------------------------------------------------------------------------

FROM ubuntu:xenial as client-builder
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install build-essential debhelper git python3-all python3-setuptools help2man bash-completion docbook-xsl xsltproc

ARG CLIENT_VERSION=1.1.0

RUN git clone --recurse-submodules https://github.com/LINBIT/linstor-api-py /linstor-api-py
WORKDIR /linstor-api-py
RUN git checkout v${CLIENT_VERSION} \
 && make debrelease \
 && mv ./dist/python-linstor-${CLIENT_VERSION}.tar.gz ../python-linstor_${CLIENT_VERSION}.orig.tar.gz \
 && tar -C / -xvf /python-linstor_${CLIENT_VERSION}.orig.tar.gz
WORKDIR /python-linstor-${CLIENT_VERSION}
RUN dpkg-buildpackage -us -uc

RUN make install

RUN git clone https://github.com/LINBIT/linstor-client.git /linstor-client
WORKDIR /linstor-client
RUN git checkout v${CLIENT_VERSION} \
 && make debrelease \
 && mv dist/linstor-client-${CLIENT_VERSION}.tar.gz /linstor-client_${CLIENT_VERSION}.orig.tar.gz \
 && tar -C / -xvf /linstor-client_${CLIENT_VERSION}.orig.tar.gz
WORKDIR /linstor-client-${CLIENT_VERSION}
RUN dpkg-buildpackage -us -uc

# ------------------------------------------------------------------------------

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
COPY --from=client-builder /python-linstor_*_all.deb /linstor-client_*_all.deb /packages/
RUN apt-get update \
 && apt-get install -y default-jre-headless linstor-client \
 && dpkg -i packages/*.deb \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /config /logs \
 && /usr/share/linstor-server/bin/linstor-config create-db-file \
      /data/linstordb > /config/linstor.toml

ENTRYPOINT [ "/usr/share/linstor-server/bin/Controller", "--logs=/logs", "--config-directory=/config" ]
