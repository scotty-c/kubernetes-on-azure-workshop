FROM golang:1.12.7-alpine3.10 as build

RUN apk add --no-cache git && \
    go get -u github.com/rakyll/hey

FROM alpine:3.10

COPY --from=build /go/bin/hey /usr/bin/hey

ENTRYPOINT [ "hey" ]
