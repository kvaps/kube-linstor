FROM golang:latest as builder
ARG CI_COMMIT_REF_NAME=
RUN mkdir -p /usr/local/go/src/github.com/LINBIT/ \
 && cd /usr/local/go/src/github.com/LINBIT/ \
 && git clone https://github.com/LINBIT/linstor-csi

RUN cd /usr/local/go/src/github.com/LINBIT/linstor-csi \
 && make staticrelease \
 && mv ./linstor-csi-linux-amd64 /

FROM quay.io/linbit/linstor-client
RUN apt-get update -y && apt-get dist-upgrade -y && apt-get install xfsprogs -y
COPY --from=builder /linstor-csi-linux-amd64 /linstor-csi
