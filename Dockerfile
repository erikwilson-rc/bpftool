# Copyright (c) 2019 Tigera, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
FROM debian:buster-slim as bpftool-build
ARG KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
ARG KERNEL_REF=master

ARG PACKAGES="gpg gpg-agent libelf-dev libmnl-dev libc-dev iptables libgcc-8-dev \
    bash-completion binutils binutils-dev ca-certificates make git curl \
    xz-utils gcc pkg-config bison flex build-essential python3"

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y --no-install-recommends ${PACKAGES}
RUN apt-get purge --auto-remove
RUN apt-get clean

WORKDIR /tmp
RUN git clone --depth 1 -b ${KERNEL_REF} ${KERNEL_REPO}

WORKDIR /tmp/linux/tools/bpf/bpftool/
RUN sed -i '/CFLAGS += -O2/a CFLAGS += -static' Makefile
RUN sed -i 's/LIBS = -lelf $(LIBBPF)/LIBS = -lelf -lz $(LIBBPF)/g' Makefile
RUN printf 'feature-libbfd=0\nfeature-libelf=1\nfeature-bpf=1\nfeature-libelf-mmap=1\nfeature-zlib=1' >> FEATURES_DUMP.bpftool
RUN FEATURES_DUMP=`pwd`/FEATURES_DUMP.bpftool make -j `getconf _NPROCESSORS_ONLN`
RUN strip bpftool
RUN ldd bpftool 2>&1 | grep -q -e "Not a valid dynamic program" -e "not a dynamic executable" || \
    ( echo "Error: bpftool is not statically linked"; false )
RUN mv bpftool /usr/bin && rm -rf /tmp/linux

FROM scratch
COPY --from=bpftool-build /usr/bin/bpftool /bpftool
