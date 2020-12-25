FROM golang:1.15 as builder

RUN git clone https://github.com/linbit/linstor-csi/ /usr/local/go/linstor-csi/ \
 && cd /usr/local/go/linstor-csi \
 && git reset --hard v0.11.0 \
 && make -f container.mk staticrelease \
 && mv ./linstor-csi-linux-amd64 /

FROM debian:buster
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      xfsprogs \
      e2fsprogs \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /linstor-csi-linux-amd64 /linstor-csi
ENTRYPOINT ["/linstor-csi"]
