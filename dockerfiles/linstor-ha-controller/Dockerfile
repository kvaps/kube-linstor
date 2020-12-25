FROM golang:1.15 as builder

RUN git clone https://github.com/kvaps/piraeus-ha-controller /usr/local/go/piraeus-ha-controller \
 && cd /usr/local/go/piraeus-ha-controller \
 && git reset --hard v0.1.1 \
 && curl -L https://github.com/piraeusdatastore/piraeus-ha-controller/pull/1.patch | git apply - \
 && cd cmd/piraeus-ha-controller \
 && go build \
 && mv ./piraeus-ha-controller /

FROM debian:buster
COPY --from=builder /piraeus-ha-controller /piraeus-ha-controller
ENTRYPOINT ["/piraeus-ha-controller"]
