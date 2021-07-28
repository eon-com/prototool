FROM alpine:latest as builder
WORKDIR /tmp
RUN apk update && apk add linux-headers g++ make autoconf libtool pkgconfig git automake python python-dev
RUN cd /tmp && git clone https://github.com/grpc/grpc && cd grpc && git submodule update --init
RUN cd grpc && make plugins -j8
ADD https://jpa.kapsi.fi/nanopb/download/nanopb-0.4.1-linux-x86.tar.gz /tmp/
RUN cd /tmp && tar xvf nanopb-0.4.1-linux-x86.tar.gz
RUN cd /tmp/nanopb-0.4.1-linux-x86/generator/proto && make

FROM uber/prototool:1.10.0 as prototool

FROM ubuntu:latest as ubuntu
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install golang-go ca-certificates git -y
ENV GO111MODULE=on
#RUN CGO_ENABLED=0 go get google.golang.org/protobuf/cmd/protoc-gen-go
#RUN CGO_ENABLED=0 go get google.golang.org/grpc/cmd/protoc-gen-go-grpc
RUN go get google.golang.org/protobuf/cmd/protoc-gen-go@v1.25.0
RUN go get google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.0.1
RUN go get github.com/chrusty/protoc-gen-jsonschema/cmd/protoc-gen-jsonschema
RUN go install github.com/chrusty/protoc-gen-jsonschema/cmd/protoc-gen-jsonschema

FROM namely/prototool:1.27_0
RUN apk add go git
RUN apk add --no-cache musl-dev
RUN apk add g++ gcc ruby-full ruby-dev make git
ADD https://github.com/grpc/grpc-web/releases/download/1.0.7/protoc-gen-grpc-web-1.0.7-linux-x86_64 /bin/protoc-gen-grpc-web
RUN chmod +x /bin/protoc-gen-grpc-web
RUN apk --no-cache add ca-certificates wget
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
RUN wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk
RUN apk add glibc-2.29-r0.apk --force
RUN apk add py-pip
RUN apk add libgcc
RUN pip install protobuf
RUN apk add python3 gcc python3-dev
RUN pip3 install "betterproto[compiler]"==1.2.5
RUN apk add nodejs npm tree libgcc
RUN npm i -g request
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
RUN wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-2.31-r0.apk
RUN cd /tmp && LD_LIBRARY_PATH=/usr/lib npm i grpc-tools && tree && cp node_modules/grpc-tools/bin/grpc_node_plugin /bin/grpc_tools_node_protoc_plugin
RUN gem update --system
RUN gem install grpc
RUN gem install grpc-tools
ADD https://github.com/grpc-ecosystem/grpc-gateway/releases/download/v2.1.0/protoc-gen-grpc-gateway-v2.1.0-linux-x86_64 /usr/local/bin/protoc-gen-grpc-gateway
RUN chmod +x /usr/local/bin/protoc-gen-grpc-gateway
ADD https://github.com/grpc-ecosystem/grpc-gateway/releases/download/v1.16.0/protoc-gen-swagger-v1.16.0-linux-x86_64 /usr/local/bin/protoc-gen-swagger
RUN chmod +x /usr/local/bin/protoc-gen-swagger
ADD https://github.com/grpc-ecosystem/grpc-gateway/releases/download/v2.1.0/protoc-gen-openapiv2-v2.1.0-linux-x86_64 /usr/local/bin/protoc-gen-openapiv2
RUN chmod +x /usr/local/bin/protoc-gen-openapiv2
ADD https://github.com/pseudomuto/protoc-gen-doc/releases/download/v1.4.0/protoc-gen-doc-1.4.0.linux-amd64.go1.15.2.tar.gz /usr/local/bin/protoc-gen-doc
RUN chmod +x /usr/local/bin/protoc-gen-doc

COPY --from=builder /tmp/grpc/bins/opt/grpc_python_plugin /bin/protoc-gen-grpc_python
COPY --from=builder /tmp/nanopb-0.4.1-linux-x86/generator/protoc-gen-nanopb /bin/
COPY --from=builder /tmp/nanopb-0.4.1-linux-x86/generator/proto /bin/proto
COPY --from=builder /tmp/nanopb-0.4.1-linux-x86/generator/nanopb /bin/nanopb
COPY --from=builder /tmp/nanopb-0.4.1-linux-x86/generator/nanopb_generator.py /bin/
COPY --from=prototool /usr/local/bin/prototool /usr/local/bin/prototool
COPY --from=prototool /usr/local/bin/prototool /usr/local/bin/prototool
COPY --from=ubuntu /root/go/bin/protoc-gen-go /usr/local/bin/protoc-gen-go
COPY --from=ubuntu /root/go/bin/protoc-gen-go-grpc /usr/local/bin/protoc-gen-go-grpc
COPY --from=ubuntu /root/go/bin/protoc-gen-jsonschema /usr/local/bin/protoc-gen-jsonschema
