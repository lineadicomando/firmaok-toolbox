#!/usr/bin/env bash

set -euo pipefail

ORIGINAL_XDG_OPEN="/usr/bin/xdg-open.real"
TARGET="${1:-}"

if [[ -n "${TARGET}" ]]; then
  RESOLVED_TARGET="${TARGET}"
  if [[ "${TARGET}" == file://* ]]; then
    RESOLVED_TARGET="${TARGET#file://}"
  fi

  if [[ -d "${RESOLVED_TARGET}" ]]; then
    exec pcmanfm "${RESOLVED_TARGET}"
  fi

  if [[ -f "${RESOLVED_TARGET}" ]]; then
    MIME_TYPE="$(xdg-mime query filetype "${RESOLVED_TARGET}" 2>/dev/null || true)"
    if [[ "${MIME_TYPE}" == "application/pdf" ]]; then
      exec xpdf "${RESOLVED_TARGET}"
    fi
  fi
fi

exec "${ORIGINAL_XDG_OPEN}" "$@"
