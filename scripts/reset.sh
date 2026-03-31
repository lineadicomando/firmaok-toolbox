#!/usr/bin/env bash

set -euo pipefail

TOOLBOX_NAME="${1:?usage: scripts/reset.sh <toolbox-name> <image-name>}"
IMAGE_NAME="${2:?usage: scripts/reset.sh <toolbox-name> <image-name>}"

podman container exists "${TOOLBOX_NAME}" && podman stop "${TOOLBOX_NAME}" || true
podman container exists "${TOOLBOX_NAME}" && podman rm "${TOOLBOX_NAME}" || true

toolbox create -c "${TOOLBOX_NAME}" -i "${IMAGE_NAME}"
