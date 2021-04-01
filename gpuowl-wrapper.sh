#!/bin/env sh


set -u

IMAGE_NAME="gpuowl"
IMAGE_TAG="${GPUOWL_TAG:-latest}"
IMAGE_REPOSITORY="${IMAGE_NAME}"

CONTAINER_ID_DIR="$(mktemp -d -t container-${IMAGE_NAME}-XXXXX)"
CONTAINER_ID_FILE="${CONTAINER_ID_DIR}/${IMAGE_NAME}.ctr-id"

CONTAINER_ENGINE=$([ -x "$(command -v podman)" ] && echo podman || echo docker)


if [ "$(getenforce)" = "Enforcing" ]  ; then
        EXTRA_CONTAINER_FLAGS='--security-opt label=type:gpuowl_container.process'
fi


start_container()
{
        ${CONTAINER_ENGINE} run --read-only --rm --cap-drop=all --network=none \
                -i --cidfile "${CONTAINER_ID_FILE}" \
                --device=/dev/kfd --device=/dev/dri \
               -v "$PWD":/in:noexec,nodev,nosuid,Z -w /in \
                ${EXTRA_CONTAINER_FLAGS:-} \
                ${IMAGE_REPOSITORY}:${IMAGE_TAG:-latest} $*
}

stop_container()
{
        echo "Stopping container..."
        trap abort INT
        nohup ${CONTAINER_ENGINE} stop --ignore --cidfile "${CONTAINER_ID_FILE}" >/dev/null 2>&1 &
        PID=$!
}

cleanup()
{
        [ -n "${PID+x}" ] && wait "${PID}"
        rm -rf "${CONTAINER_ID_DIR}"
}

abort()
{
        echo "Aborted."
        exit 255
}

trap stop_container TERM INT QUIT HUP
start_container $*
EXIT_CODE=$?
cleanup
exit "${EXIT_CODE}"
