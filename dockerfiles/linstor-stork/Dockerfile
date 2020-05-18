FROM golang:1 as builder
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      go-dep \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
RUN git clone --single-branch --branch linstor-configurable-endpoint \
      https://github.com/kvaps/stork /go/src/github.com/libopenstorage/stork \
 && git clone --single-branch --branch fix-http2curl \
      https://github.com/kvaps/golinstor /go/src/github.com/LINBIT/golinstor/

WORKDIR /go/src/github.com/libopenstorage/stork
RUN cd cmd/stork && go get -d -u
RUN cd cmd/storkctl && go get -d -u
RUN make stork storkctl \
 && mv bin/stork bin/linux/storkctl /

FROM debian:buster
COPY --from=builder /stork /storkctl /
ENTRYPOINT ["/stork"]
