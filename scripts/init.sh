#!/usr/bin/env bash

set -euo pipefail

CONTAINER_NAME="${1:?usage: scripts/init.sh <container-name>}"
CONTAINER_BACKEND="${CONTAINER_BACKEND:-toolbox}"
SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="${SCRIPT_PATH%/*}"
if [[ "${SCRIPT_DIR}" == "${SCRIPT_PATH}" ]]; then
  SCRIPT_DIR='.'
fi
SCRIPT_DIR="$(cd "${SCRIPT_DIR}" && pwd)"

bash "${SCRIPT_DIR}/container-backend.sh" run "${CONTAINER_BACKEND}" "${CONTAINER_NAME}" \
  env \
  FIRMAOK_TOOLBOX_NAME="${CONTAINER_NAME}" \
  FIRMAOK_CONTAINER_NAME="${CONTAINER_NAME}" \
  FIRMAOK_CONTAINER_BACKEND="${CONTAINER_BACKEND}" \
  /usr/local/bin/init-firmaok.sh

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "${HOME}/.local/share/icons/hicolor" || true
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${HOME}/.local/share/applications/" || true
fi
