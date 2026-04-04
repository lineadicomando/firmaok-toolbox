#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: scripts/container-backend.sh <validate|create|enter|run|reset> <toolbox|distrobox> <name> [args...]\n' >&2
}

action="${1:-}"
backend="${2:-}"
name="${3:-}"

if [[ -z "$action" || -z "$backend" || -z "$name" ]]; then
  usage
  exit 1
fi

shift 3

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing command: %s\n' "$1" >&2
    exit 1
  }
}

require_podman() {
  require_cmd podman
}

podman_container_exists() {
  local container_name="$1"
  local rc

  if podman container exists "$container_name"; then
    return 0
  else
    rc=$?
  fi

  if [[ "$rc" -eq 1 ]]; then
    return 1
  fi

  printf 'podman container exists failed for %s (exit %s)\n' "$container_name" "$rc" >&2
  exit "$rc"
}

validate_backend() {
  case "$1" in
    toolbox|distrobox) ;;
    *)
      printf 'Unsupported backend: %s\n' "$1" >&2
      exit 1
      ;;
  esac
}

backend_cli() {
  case "$1" in
    toolbox)
      printf 'toolbox\n'
      ;;
    distrobox)
      printf 'distrobox\n'
      ;;
  esac
}

validate() {
  validate_backend "$backend"
  require_podman
  require_cmd "$(backend_cli "$backend")"
}

backend_create() {
  local image="$1"

  validate
  if podman_container_exists "$name"; then
    return 0
  fi

  case "$backend" in
    toolbox)
      toolbox create -c "$name" -i "$image"
      ;;
    distrobox)
      distrobox create --name "$name" --image "$image"
      ;;
  esac
}

backend_enter() {
  validate

  case "$backend" in
    toolbox)
      toolbox enter -c "$name"
      ;;
    distrobox)
      distrobox enter -n "$name"
      ;;
  esac
}

backend_run() {
  if [[ "$#" -eq 0 ]]; then
    printf 'Usage: scripts/container-backend.sh run <%s> <%s> <command> [args...]\n' "toolbox|distrobox" "name" >&2
    exit 1
  fi

  validate

  case "$backend" in
    toolbox)
      toolbox run -c "$name" "$@"
      ;;
    distrobox)
      distrobox enter -n "$name" -- "$@"
      ;;
  esac
}

backend_reset() {
  local image="$1"
  local stop_rc
  local rm_force_rc

  validate
  if podman_container_exists "$name"; then
    if podman stop "$name"; then
      podman rm "$name"
    else
      stop_rc=$?
      if podman rm -f "$name"; then
        :
      else
        rm_force_rc=$?
        printf 'Failed to clean up container %s after stop failure (stop exit %s, rm -f exit %s)\n' "$name" "$stop_rc" "$rm_force_rc" >&2
        exit "$rm_force_rc"
      fi
    fi
  fi
  backend_create "$image"
}

case "$action" in
  validate)
    if [[ "$#" -ne 0 ]]; then
      usage
      exit 1
    fi
    validate
    ;;
  create)
    image="${1:-}"
    if [[ -z "$image" || "$#" -ne 1 ]]; then
      printf 'Usage: scripts/container-backend.sh create <toolbox|distrobox> <name> <image>\n' >&2
      exit 1
    fi
    backend_create "$image"
    ;;
  enter)
    if [[ "$#" -ne 0 ]]; then
      printf 'Usage: scripts/container-backend.sh enter <toolbox|distrobox> <name>\n' >&2
      exit 1
    fi
    backend_enter
    ;;
  run)
    backend_run "$@"
    ;;
  reset)
    image="${1:-}"
    if [[ -z "$image" || "$#" -ne 1 ]]; then
      printf 'Usage: scripts/container-backend.sh reset <toolbox|distrobox> <name> <image>\n' >&2
      exit 1
    fi
    backend_reset "$image"
    ;;
  *)
    printf 'Unsupported action: %s\n' "$action" >&2
    exit 1
    ;;
esac
