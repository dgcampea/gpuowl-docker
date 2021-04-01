#!/bin/bash

set -ue

usage()
{
    echo "Options:
            -l, --latest                        Tag this image as latest.
            -c, --checkout COMMIT/BRANCH        Build <COMMIT/BRANCH>.
            -r, --rocm-ver ROCM-VERSION         Use <ROCM-VERSION> for ROCm.
                                                Image will be named as gpuowl-<ROCM-VERSION>."
    exit 0
}

# defaults
#
LATEST=0
CHECKOUT=HEAD
ROCM_VERSION=latest

# see: https://www.shellscript.sh/tips/getopt/

PARSED_ARGUMENTS=$(getopt -o lc:r: --long latest,checkout:,rocm-ver: -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
  usage
fi

eval set -- "$PARSED_ARGUMENTS"
while :
do
  case "$1" in
    -l | --latest)          LATEST=1            ; shift   ;;
    -c | --checkout)        CHECKOUT="$2"       ; shift 2 ;;
    -r | --rocm-ver)        ROCM_VERSION="$2"   ; shift 2 ;;
    # -- means the end of the arguments; drop this, and break out of the while loop
    --) shift; break ;;
    # If invalid options were passed, then getopt should have reported an error,
    # which we checked as VALID_ARGUMENTS when getopt was called...
    *) echo "Unexpected option: $1 - this should not happen."
       usage ;;
  esac
done


# build logic
#

# constants
BUILD_BASE_IMAGE="docker.io/rocm/dev-ubuntu-20.04:${ROCM_VERSION}"
RUN_BASE_IMAGE="$BUILD_BASE_IMAGE"
IMAGE_NAME=$([ "${ROCM_VERSION}" = "latest" ] && echo "gpuowl" || echo "gpuowl-${ROCM_VERSION}")


BUILD_CTR=$(buildah from ${BUILD_BASE_IMAGE})
buildah config --workingdir /build --env=DEBIAN_FRONTEND=noninteractive ${BUILD_CTR}
buildah run ${BUILD_CTR} /bin/sh -c 'apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates git libgmp-dev python3-minimal'

buildah run ${BUILD_CTR} /bin/sh -c "git init \
    && git remote add origin https://github.com/preda/gpuowl.git \
    && git fetch --tags origin ${CHECKOUT} \
    && git reset --hard FETCH_HEAD"

buildah run ${BUILD_CTR} make


FINAL_CTR=$(buildah from ${RUN_BASE_IMAGE})
buildah config --env=DEBIAN_FRONTEND=noninteractive ${FINAL_CTR}
buildah run ${FINAL_CTR} /bin/sh -c 'apt-get update \
    && apt-get install --no-install-recommends -y \
        libgmp10 libquadmath0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*'

buildah config --env=DEBIAN_FRONTEND- ${FINAL_CTR}
buildah run ${FINAL_CTR} mkdir /app

# mounting
{
    BUILD_MNT=$(buildah mount ${BUILD_CTR})
    FINAL_MNT=$(buildah mount ${FINAL_CTR})
    
    cp "${BUILD_MNT}/build/gpuowl" "${FINAL_MNT}/app/gpuowl"
    buildah unmount ${BUILD_CTR} ${FINAL_CTR}
}


GPUOWL_VERSION=$(buildah run ${BUILD_CTR} cat version.inc | tr -d '"')
GPUOWL_LONG_COMMIT=$(buildah run ${BUILD_CTR} git rev-parse HEAD)

buildah config --stop-signal=SIGINT \
    --entrypoint '["/usr/bin/stdbuf", "-oL", "/app/gpuowl"]' \
    --cmd "" \
    --volume /in \
    --workingdir /in ${FINAL_CTR}

buildah config --annotation=org.opencontainers.image.title=gpuowl \
    --annotation=org.opencontainers.image.licenses=GPL-3.0 \
    --annotation=org.opencontainers.image.version="${GPUOWL_VERSION}" \
    --annotation=org.opencontainers.image.revision=${GPUOWL_LONG_COMMIT} \
    --annotation=org.opencontainers.image.url="https://github.com/dgcampea/gpuowl-docker" ${FINAL_CTR}

buildah commit ${FINAL_CTR} ${IMAGE_NAME}:${GPUOWL_VERSION}
if [ $LATEST -eq 1 ]; then
    buildah tag ${IMAGE_NAME}:${GPUOWL_VERSION} ${IMAGE_NAME}:latest
fi

buildah rm ${BUILD_CTR} ${FINAL_CTR}
