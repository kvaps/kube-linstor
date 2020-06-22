FROM golang:1 as builder
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      go-dep \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/LINBIT/stork /go/src/github.com/libopenstorage/stork \
 && cd /go/src/github.com/libopenstorage/stork \
 && git reset --hard v1.3.0-beta1-615-g14b2aadf

RUN git clone https://github.com/kvaps/golinstor /go/src/github.com/LINBIT/golinstor \
 && cd /go/src/github.com/LINBIT/golinstor \
 && git reset --hard v0.26.0-4-g7731c9f

WORKDIR /go/src/github.com/libopenstorage/stork
RUN cd cmd/stork \
 && go get -d -u
RUN cd cmd/storkctl \
 && go get -d -u

RUN make stork storkctl \
 && mv bin/stork bin/linux/storkctl /

FROM debian:buster
COPY --from=builder /stork /storkctl /
ENTRYPOINT ["/stork"]
