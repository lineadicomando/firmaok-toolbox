#!/usr/bin/env bash

set -euo pipefail

ORIGINAL_XDG_OPEN="/usr/bin/xdg-open.real"
TARGET="${1:-}"
DEBUG="${FIRMAOK_WRAPPER_DEBUG:-0}"

debug() {
  if [[ "${DEBUG}" == "1" ]]; then
    printf '[xdg-open-wrapper] %s\n' "$*" >&2
  fi
}

debug "argv: $*"

if [[ -n "${TARGET}" ]]; then
  RESOLVED_TARGET="${TARGET}"
  debug "initial target: ${TARGET}"
  if [[ "${TARGET}" == file://* ]]; then
    RESOLVED_TARGET="${TARGET#file://}"
    debug "file uri detected, resolved target: ${RESOLVED_TARGET}"
  fi

  if [[ -d "${RESOLVED_TARGET}" ]]; then
    debug "directory detected, opening with pcmanfm"
    exec pcmanfm "${RESOLVED_TARGET}"
  fi

  if [[ -f "${RESOLVED_TARGET}" ]]; then
    debug "file detected, querying mime type"
    MIME_TYPE="$(xdg-mime query filetype "${RESOLVED_TARGET}" 2>/dev/null || true)"
    debug "mime type: ${MIME_TYPE:-<empty>}"
    if [[ "${MIME_TYPE}" == "application/pdf" ]]; then
      debug "pdf detected, opening with xpdf"
      exec xpdf "${RESOLVED_TARGET}"
    fi
  fi
fi

debug "falling back to original xdg-open"
exec "${ORIGINAL_XDG_OPEN}" "$@"
