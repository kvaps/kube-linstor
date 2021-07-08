FROM registry.access.redhat.com/ubi7/ubi as builder

ENV DRBD_REACTOR_VERSION 0.4.0

ENV DRBD_REACTOR_TGZNAME drbd-reactor
ENV DRBD_REACTOR_TGZ ${DRBD_REACTOR_TGZNAME}-${DRBD_REACTOR_VERSION}.tar.gz

USER root
# need to setup our own toolchain to cover archs not in rust:lastest
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile minimal -y -q --no-modify-path # !lbbuild

RUN yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical && yum install -y gcc wget && yum clean all -y # !lbbuild

# one can not comment COPY
RUN cd /tmp && wget https://pkg.linbit.com/downloads/drbd/utils/${DRBD_REACTOR_TGZ} # !lbbuild
# =lbbuild COPY /${DRBD_REACTOR_TGZ} /tmp/

# =lbbuild USER makepkg
RUN cd /tmp && tar xvf ${DRBD_REACTOR_TGZ} && cd ${DRBD_REACTOR_TGZNAME}-${DRBD_REACTOR_VERSION} && \
	. $HOME/.cargo/env; cargo install --path . && \
	cp $HOME/.cargo/bin/drbd-reactor /tmp

FROM quay.io/linbit/drbd-utils
MAINTAINER Roland Kammerer <roland.kammerer@linbit.com>

ENV DRBD_REACTOR_VERSION 0.4.0

ARG release=1
LABEL	name="drbd-reactor" \
	vendor="LINBIT" \
	version="$DRBD_REACTOR_VERSION" \
	release="$release" \
	summary="DRBD events reaction via plugins" \
	description="DRBD events reaction via plugins"

COPY --from=builder /tmp/drbd-reactor /usr/sbin
COPY drbd-reactor.toml /etc

RUN yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical && \
	yum clean all -y

ENTRYPOINT ["/usr/sbin/drbd-reactor"]