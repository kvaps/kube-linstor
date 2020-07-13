FROM golang:1 as builder
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      go-dep \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/LINBIT/stork /go/src/github.com/libopenstorage/stork \
 && cd /go/src/github.com/libopenstorage/stork \
 && git reset --hard v1.3.0-beta1-628-g7398fc4e

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
