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

FROM debian:buster as client-builder

ARG CLIENT_VERSION=1.6.0

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install build-essential debhelper git python3-all python3-setuptools help2man bash-completion docbook-xsl xsltproc

RUN git clone --recurse-submodules https://github.com/LINBIT/linstor-api-py /linstor-api-py
WORKDIR /linstor-api-py
RUN git checkout v${CLIENT_VERSION} \
 && make debrelease \
 && mv ./dist/python-linstor-${CLIENT_VERSION}.tar.gz ../python-linstor_${CLIENT_VERSION}.orig.tar.gz \
 && tar -C / -xvf /python-linstor_${CLIENT_VERSION}.orig.tar.gz
WORKDIR /python-linstor-${CLIENT_VERSION}
RUN dpkg-buildpackage -us -uc

RUN rm -rf /linstor-api-py \
 && mv /python-linstor-${CLIENT_VERSION} /linstor-api-py

RUN git clone https://github.com/LINBIT/linstor-client.git /linstor-client
WORKDIR /linstor-client
RUN git checkout v${CLIENT_VERSION} \
 && make debrelease \
 && mv dist/linstor-client-${CLIENT_VERSION}.tar.gz /linstor-client_${CLIENT_VERSION}.orig.tar.gz \
 && tar -C / -xvf /linstor-client_${CLIENT_VERSION}.orig.tar.gz
WORKDIR /linstor-client-${CLIENT_VERSION}
RUN dpkg-buildpackage -us -uc

# ------------------------------------------------------------------------------

FROM golang:1.15 as k8s-await-election-builder

RUN git clone https://github.com/LINBIT/k8s-await-election/ /usr/local/go/k8s-await-election/ \
 && cd /usr/local/go/k8s-await-election \
 && git reset --hard v0.2.0 \
 && make \
 && mv ./out/k8s-await-election /

# ------------------------------------------------------------------------------

FROM debian:buster

COPY --from=builder /linstor-common_*_all.deb /linstor-controller_*_all.deb /packages/
COPY --from=client-builder /python-linstor_*_all.deb /linstor-client_*_all.deb /packages/
COPY --from=k8s-await-election-builder /k8s-await-election /k8s-await-election

# Install repos and system upgrade
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update \
 && apt-get -y upgrade \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install linstor-controller
RUN apt-get update \
 && apt-get install -y default-jre-headless python3-all python3-natsort \
 && dpkg -i packages/*.deb \
 && sed -i "s|'$| \"-Djdk.tls.acknowledgeCloseNotify=true\"'|" \
      /usr/share/linstor-server/bin/Controller \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /config /logs \
 && /usr/share/linstor-server/bin/linstor-config create-db-file \
      /data/linstordb > /config/linstor.toml

ENTRYPOINT [ "/usr/share/linstor-server/bin/Controller", "--logs=/logs", "--config-directory=/config" ]
