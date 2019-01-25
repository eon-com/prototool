FROM alpine:latest as builder
WORKDIR /tmp
RUN apk update && apk add  g++ make autoconf libtool pkgconfig git automake
RUN cd /tmp && git clone https://github.com/grpc/grpc && cd grpc && git submodule update --init
RUN cd grpc && make plugins -j8

FROM namely/prototool:1.17_0
RUN apk add g++
COPY --from=builder /tmp/grpc/bins/opt/grpc_python_plugin /bin/protoc-gen-grpc_python

