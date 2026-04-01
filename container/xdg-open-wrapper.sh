#!/bin/sh

set -eu

if command -v flatpak-spawn >/dev/null 2>&1; then
  if flatpak-spawn --host /usr/bin/xdg-open "$@"; then
    exit 0
  fi
fi

if command -v gio >/dev/null 2>&1; then
  exec gio open "$@"
fi

printf '%s\n' "xdg-open-wrapper: impossibile aprire la risorsa (flatpak-spawn/gio non disponibili)" >&2
exit 1
