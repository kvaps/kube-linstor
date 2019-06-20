FROM golang:latest as builder
ARG CI_COMMIT_REF_NAME=
RUN mkdir -p /usr/local/go/src/github.com/kvaps/ \
 && cd /usr/local/go/src/github.com/kvaps/ \
 && git clone https://github.com/kvaps/linstor-flexvolume \
 && cd linstor-flexvolume \
 && CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o /linstor-flexvolume

FROM ubuntu:bionic
ARG CI_COMMIT_REF_NAME=
ENV DEBIAN_FRONTEND noninteractive

# Install repos and system upgrade
RUN apt-get -y update \
 && apt-get install -y wget gnupg \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC1B5A793C04BB3905AD837734893610CEAA9512 \
 && echo "deb http://ppa.launchpad.net/linbit/linbit-drbd9-stack/ubuntu bionic main" \
      > /etc/apt/sources.list.d/linbit.list \
 && apt-get update \
 && apt-get -y upgrade \
 && apt-get clean

# Install linstor-client and tools
RUN apt-get update \
 && apt-get install -y linstor-client bash-completion \
 && apt-get clean

COPY --from=builder /linstor-flexvolume /linstor-flexvolume
ADD install.sh /

CMD ["/install.sh"]
