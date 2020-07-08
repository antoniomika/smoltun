FROM ubuntu:latest as builder

WORKDIR /dropbear

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y build-essential wget git autoconf libtool musl-dev musl-tools
RUN ln -s "/usr/bin/g++" "/usr/bin/musl-g++"

ARG DROPBEAR_VERSION=DROPBEAR_2020.80

RUN git clone https://github.com/mkj/dropbear /dropbear && git checkout ${DROPBEAR_VERSION}
RUN autoconf && autoheader
RUN CC=musl-gcc LDFLAGS="-L/usr/local/musl/lib" CFLAGS="-I/usr/local/musl/include" ./configure --prefix=/usr/local/musl --enable-static --disable-zlib --disable-syslog
RUN make PROGRAMS="dbclient"

WORKDIR /autossh

ARG AUTOSSH_VERSION=1.4g

RUN wget https://www.harding.motd.ca/autossh/autossh-${AUTOSSH_VERSION}.tgz
RUN tar -xvf autossh-${AUTOSSH_VERSION}.tgz

WORKDIR /autossh/autossh-${AUTOSSH_VERSION}

RUN CC=musl-gcc LDFLAGS="-L/usr/local/musl/lib -static" CFLAGS="-I/usr/local/musl/include" ./configure
RUN make

RUN mkdir -p /scratchfs/tmp /scratchfs/etc /scratchfs/root /scratchfs/usr/bin && \
    cp /etc/passwd /scratchfs/etc/passwd && \
    cp /autossh/autossh-${AUTOSSH_VERSION}/autossh /scratchfs/usr/bin/autossh && \
    cp /dropbear/dbclient /scratchfs/usr/bin/ssh

FROM scratch

COPY --from=builder /scratchfs /

ENTRYPOINT ["/usr/bin/autossh"]

