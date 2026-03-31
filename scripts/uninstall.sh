#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 2 ]]; then
  printf 'Usage: scripts/uninstall.sh <toolbox-name> <image-name>\n' >&2
  exit 1
fi

TOOLBOX_NAME="$1"
IMAGE_NAME="$2"

log_in_corso() {
  printf '[IN CORSO] %s\n' "$1"
}

log_ok() {
  printf '[OK] %s\n' "$1"
}

log_skip() {
  printf '[SKIP] %s\n' "$1"
}

log_errore() {
  printf '[ERRORE] %s\n' "$1" >&2
}

stop_container_if_exists() {
  local name="$1"
  local running

  log_in_corso "Arresto del container ${name}"
  if podman container exists "${name}"; then
    if running="$(podman inspect -f '{{.State.Running}}' "${name}")"; then
      if [[ "${running}" == "true" ]]; then
        if podman stop "${name}"; then
          log_ok "Container ${name} arrestato"
        else
          log_errore "Impossibile arrestare il container ${name}"
          exit 1
        fi
      else
        log_skip "Container ${name} gia' arrestato"
      fi
    else
      log_errore "Impossibile determinare lo stato del container ${name}"
      exit 1
    fi
  else
    log_skip "Container ${name} non presente"
  fi
}

remove_container_if_exists() {
  local name="$1"

  log_in_corso "Rimozione del container ${name}"
  if podman container exists "${name}"; then
    if podman rm "${name}"; then
      log_ok "Container ${name} rimosso"
    else
      log_errore "Impossibile rimuovere il container ${name}"
      exit 1
    fi
  else
    log_skip "Container ${name} gia' assente"
  fi
}

remove_image_if_exists() {
  local name="$1"

  log_in_corso "Rimozione dell'immagine ${name}"
  if podman image exists "${name}"; then
    if podman rmi "${name}"; then
      log_ok "Immagine ${name} rimossa"
    else
      log_errore "Impossibile rimuovere l'immagine ${name}"
      exit 1
    fi
  else
    log_skip "Immagine ${name} gia' assente"
  fi
}

remove_directory_if_exists() {
  local path="$1"

  log_in_corso "Rimozione directory ${path}"
  if [[ -d "${path}" ]]; then
    if rm -rf "${path}"; then
      log_ok "Directory ${path} rimossa"
    else
      log_errore "Impossibile rimuovere la directory ${path}"
      exit 1
    fi
  else
    log_skip "Directory ${path} gia' assente"
  fi
}

remove_file_if_exists() {
  local path="$1"

  log_in_corso "Rimozione file ${path}"
  if [[ -e "${path}" || -L "${path}" ]]; then
    if rm -f "${path}"; then
      log_ok "File ${path} rimosso"
    else
      log_errore "Impossibile rimuovere il file ${path}"
      exit 1
    fi
  else
    log_skip "File ${path} gia' assente"
  fi
}

printf 'Stai per disinstallare firmaOK dal toolbox "%s".\n' "${TOOLBOX_NAME}"
printf "Questa operazione e' irreversibile: impostazioni e personalizzazioni locali andranno perse.\n"
printf 'Potrai reinstallare in seguito con: make setup\n\n'

read -r -p 'Confermi la disinstallazione? [s/N] ' CONFIRM

if [[ "${CONFIRM}" != "s" && "${CONFIRM}" != "S" ]]; then
  log_skip "Disinstallazione annullata dall'utente"
  exit 0
fi

stop_container_if_exists "${TOOLBOX_NAME}"
remove_container_if_exists "${TOOLBOX_NAME}"
remove_image_if_exists "${IMAGE_NAME}"

remove_directory_if_exists "${HOME}/.local/opt/firmaOK"
remove_file_if_exists "${HOME}/.local/bin/firmaOK"
remove_file_if_exists "${HOME}/.local/share/icons/hicolor/256x256/apps/firmaok.png"
remove_file_if_exists "${HOME}/.local/share/applications/firmaOk.desktop"

log_ok 'Disinstallazione completata'
