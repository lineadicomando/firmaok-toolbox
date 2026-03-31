#!/usr/bin/env bash

set -euo pipefail

TOOLBOX_NAME="${1:?usage: scripts/init.sh <toolbox-name>}"

toolbox run -c "${TOOLBOX_NAME}" env FIRMAOK_TOOLBOX_NAME="${TOOLBOX_NAME}" /usr/local/bin/init-firmaok.sh

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "${HOME}/.local/share/icons/hicolor" || true
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${HOME}/.local/share/applications/" || true
fi
