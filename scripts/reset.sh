#!/usr/bin/env bash

set -euo pipefail

CONTAINER_NAME="${1:?usage: scripts/reset.sh <container-name> <image-name>}"
IMAGE_NAME="${2:?usage: scripts/reset.sh <container-name> <image-name>}"
CONTAINER_BACKEND="${CONTAINER_BACKEND:-toolbox}"
SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="${SCRIPT_PATH%/*}"
if [[ "${SCRIPT_DIR}" == "${SCRIPT_PATH}" ]]; then
  SCRIPT_DIR='.'
fi
SCRIPT_DIR="$(cd "${SCRIPT_DIR}" && pwd)"

bash "${SCRIPT_DIR}/container-backend.sh" reset "${CONTAINER_BACKEND}" "${CONTAINER_NAME}" "${IMAGE_NAME}"
