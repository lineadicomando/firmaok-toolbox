#!/usr/bin/env bash

set -euo pipefail

ARCHIVE_URL="https://postecert.poste.it/firma/download/firmaoksetup/firmaOK_Linux.tar.gz"
ARCHIVE_PATH="/tmp/firmaOK_Linux.tar.gz"
APP_DIR="${HOME}/.local/opt/firmaOK"
BIN_DIR="${HOME}/.local/bin"
ICON_DIR="${HOME}/.local/share/icons/hicolor/256x256/apps"
APPLICATIONS_DIR="${HOME}/.local/share/applications"
LAUNCHER_PATH="${APP_DIR}/launcher_linux.com"
ICON_SOURCE_PATH="${APP_DIR}/System/Commons/links/icon.png"
TOOLBOX_NAME="${FIRMAOK_TOOLBOX_NAME:-firmaok-toolbox}"
WRAPPER_PATH="${BIN_DIR}/firmaOK"

mkdir -p "${APP_DIR}" "${BIN_DIR}" "${ICON_DIR}" "${APPLICATIONS_DIR}"

if [[ ! -x "${LAUNCHER_PATH}" || ! -f "${ICON_SOURCE_PATH}" || $(grep -c 'ulimit -c 0' "${LAUNCHER_PATH}" 2>/dev/null || true) -gt 0 ]]; then
  wget --show-progress --progress=bar:force:noscroll -O "${ARCHIVE_PATH}" "${ARCHIVE_URL}"
  tar xzf "${ARCHIVE_PATH}" -C "${APP_DIR}"
  rm -f "${ARCHIVE_PATH}"
fi

rm -f "${WRAPPER_PATH}"
cat >"${WRAPPER_PATH}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0
exec "${LAUNCHER_PATH}" "\$@"
EOF
chmod +x "${WRAPPER_PATH}"
ln -sfn "${ICON_SOURCE_PATH}" "${ICON_DIR}/firmaok.png"

cat >"${APPLICATIONS_DIR}/firmaOk.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=firmaOK
Exec=toolbox run -c ${TOOLBOX_NAME} firmaOK
Icon=${ICON_DIR}/firmaok.png
Categories=Utility;
Terminal=false
StartupWMClass=kickstart.exe
EOF

printf 'firmaOK initialized in %s\n' "${APP_DIR}"
