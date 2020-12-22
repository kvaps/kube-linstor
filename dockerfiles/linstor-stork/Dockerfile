FROM golang:1.15 as builder
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      go-dep \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/libopenstorage/stork /go/src/github.com/libopenstorage/stork \
 && cd /go/src/github.com/libopenstorage/stork \
 && git reset --hard v2.6.1
# && rm -f Gopkg.lock Gopkg.toml \
# && go mod init

RUN GO111MODULE=on go get -u -d github.com/libopenstorage/stork@v2.6.1
WORKDIR /go/src/github.com/libopenstorage/stork

#RUN cd cmd/stork \
# && go get -d -u
#RUN cd cmd/storkctl \
# && go get -d -u

RUN make vendor

RUN make stork storkctl \
 && mv bin/stork bin/linux/storkctl /

FROM debian:buster
COPY --from=builder /stork /storkctl /
ENTRYPOINT ["/stork"]
