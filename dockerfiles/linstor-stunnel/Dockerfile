FROM alpine:3.10

RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community stunnel

ENTRYPOINT [ "/usr/bin/stunnel" ]
