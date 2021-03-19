#
# Hack for AMD rocm-opencl(-dev) packages (https://github.com/RadeonOpenCompute/ROCm/issues/1134)
#        SHELL ["/bin/bash", "-o", "pipefail", "-c"]
#        ln -s "$(find /opt -type d -name 'rocm-*')" /opt/rocm &&
#        echo /opt/rocm/opencl/lib > /etc/ld.so.conf.d/x86_64-rocm-opencl.conf && ldconfig
#
# AMD probably builds these using something older than ubuntu:20.04
#     ldd  /opt/rocm/lib/libamd_comgr.so:
#	        linux-vdso.so.1 (0x00007ffc503dc000)
#             libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fd62e38c000)
#	        libtinfo.so.5 => not found
#


FROM ubuntu:20.04 AS rocm

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
                curl gnupg ca-certificates \
        && curl -sL https://repo.radeon.com/rocm/rocm.gpg.key | apt-key add - \
        && echo "deb [arch=amd64] https://repo.radeon.com/rocm/apt/debian/ xenial main" > /etc/apt/sources.list.d/rocm.list \
        && apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
                rocm-opencl libtinfo5 \
        && apt-get -y purge curl gnupg && apt-get -y autoremove \
        && apt-get clean && rm -rf /var/lib/apt/lists/*  \
        && ln -s "$(find /opt -type d -name 'rocm-*')" /opt/rocm && echo /opt/rocm/opencl/lib > /etc/ld.so.conf.d/x86_64-rocm-opencl.conf && ldconfig


FROM rocm AS builder-env

RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
                g++ make git python3-minimal libgmp-dev rocm-opencl-dev \
        && apt-get clean && rm -rf /var/lib/apt/lists/*


FROM builder-env AS builder
ARG COMMIT

WORKDIR /build
RUN git init \
        && git remote add origin https://github.com/preda/gpuowl.git \
        && git fetch --tags origin ${COMMIT} \
        && git reset --hard FETCH_HEAD \
        && make


FROM rocm AS application

RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
                libgmp10 libquadmath0 \
        && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/gpuowl /app/
RUN mkdir /in

WORKDIR /in
VOLUME /in
STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/bin/stdbuf", "-oL", "/app/gpuowl"]
