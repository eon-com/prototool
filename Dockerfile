FROM alpine:latest as builder
WORKDIR /tmp
RUN apk update && apk add linux-headers g++ make autoconf libtool pkgconfig git automake
RUN cd /tmp && git clone https://github.com/grpc/grpc && cd grpc && git submodule update --init
RUN cd grpc && make plugins -j8

FROM namely/prototool:1.17_0
RUN apk add g++
ADD https://github.com/grpc/grpc-web/releases/download/1.0.7/protoc-gen-grpc-web-1.0.7-linux-x86_64 /bin/protoc-gen-grpc-web
RUN chmod +x /bin/protoc-gen-grpc-web
COPY --from=builder /tmp/grpc/bins/opt/grpc_python_plugin /bin/protoc-gen-grpc_python

