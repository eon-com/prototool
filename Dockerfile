FROM ubuntu:16.04 as builder
WORKDIR /tmp
RUN apt update && apt install  build-essential autoconf libtool pkg-config git -y
RUN cd /tmp && git clone https://github.com/grpc/grpc && cd grpc && git submodule update --init
RUN cd grpc && make plugins -j8

FROM namely/prototool:1.17_0
COPY --from=builder /tmp/grpc/bins/opt/grpc_python_plugin /bin/protoc-gen-grpc_python

