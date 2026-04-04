#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${ROOT_DIR}/scripts/container-backend.sh"
INIT_SCRIPT="${ROOT_DIR}/scripts/init.sh"
RESET_SCRIPT="${ROOT_DIR}/scripts/reset.sh"
CONTAINER_INIT_SCRIPT="${ROOT_DIR}/container/init-firmaok.sh"
BASH_BIN="$(command -v bash)"

TMP_DIR=""
FAKE_BIN=""
LOG_FILE=""
PODMAN_STATE_FILE=""

cleanup() {
  if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
    rm -rf "${TMP_DIR}"
  fi
}

setup_fake_env() {
  TMP_DIR="$(mktemp -d)"
  FAKE_BIN="${TMP_DIR}/bin"
  LOG_FILE="${TMP_DIR}/calls.log"
  PODMAN_STATE_FILE="${TMP_DIR}/podman-state.txt"
  BACKEND_TEST_PODMAN_EXISTS_NAMES=''
  BACKEND_TEST_PODMAN_EXISTS_RC=''
  BACKEND_TEST_PODMAN_FAIL_STOP='0'
  BACKEND_TEST_PODMAN_FAIL_RM='0'
  mkdir -p "${FAKE_BIN}"
  : >"${LOG_FILE}"
  : >"${PODMAN_STATE_FILE}"

  cat >"${FAKE_BIN}/podman" <<'EOF'
#!/bin/bash
set -euo pipefail

printf 'podman|%s\n' "$*" >>"${BACKEND_TEST_LOG_FILE}"

contains_name() {
  local state_file="$1"
  local needle="$2"
  local item
  while IFS= read -r item; do
    if [[ "${item}" == "${needle}" ]]; then
      return 0
    fi
  done <"${state_file}"
  return 1
}

remove_name() {
  local state_file="$1"
  local needle="$2"
  local item
  local next_state=""

  while IFS= read -r item; do
    if [[ "${item}" != "${needle}" && -n "${item}" ]]; then
      next_state+="${item}"$'\n'
    fi
  done <"${state_file}"

  printf '%s' "${next_state}" >"${state_file}"
}

if [[ "${1:-}" == "container" && "${2:-}" == "exists" ]]; then
  if [[ -n "${BACKEND_TEST_PODMAN_EXISTS_RC:-}" ]]; then
    exit "${BACKEND_TEST_PODMAN_EXISTS_RC}"
  fi
  if contains_name "${BACKEND_TEST_PODMAN_STATE_FILE}" "${3:-}"; then
    exit 0
  fi
  exit 1
fi

if [[ "${1:-}" == "stop" && "${BACKEND_TEST_PODMAN_FAIL_STOP:-0}" == "1" ]]; then
  exit 42
fi

if [[ "${1:-}" == "rm" && "${BACKEND_TEST_PODMAN_FAIL_RM:-0}" == "1" ]]; then
  exit 43
fi

if [[ "${1:-}" == "rm" ]]; then
  if [[ "${2:-}" == "-f" ]]; then
    remove_name "${BACKEND_TEST_PODMAN_STATE_FILE}" "${3:-}"
  else
    remove_name "${BACKEND_TEST_PODMAN_STATE_FILE}" "${2:-}"
  fi
fi
EOF

  cat >"${FAKE_BIN}/toolbox" <<'EOF'
#!/bin/bash
set -euo pipefail
printf 'toolbox|%s\n' "$*" >>"${BACKEND_TEST_LOG_FILE}"
EOF

  cat >"${FAKE_BIN}/distrobox" <<'EOF'
#!/bin/bash
set -euo pipefail
printf 'distrobox|%s\n' "$*" >>"${BACKEND_TEST_LOG_FILE}"
EOF

  cat >"${FAKE_BIN}/bash" <<EOF
#!/bin/bash
exec "${BASH_BIN}" "\$@"
EOF

  chmod +x "${FAKE_BIN}/podman" "${FAKE_BIN}/toolbox" "${FAKE_BIN}/distrobox" "${FAKE_BIN}/bash"
}

assert_in_log() {
  local expected="$1"
  if ! grep -Fqx "$expected" "${LOG_FILE}"; then
    printf 'Expected log entry not found: %s\n' "$expected" >&2
    printf 'Captured log:\n' >&2
    cat "${LOG_FILE}" >&2
    exit 1
  fi
}

assert_not_in_log() {
  local unexpected="$1"
  if grep -Fqx "$unexpected" "${LOG_FILE}"; then
    printf 'Unexpected log entry found: %s\n' "$unexpected" >&2
    printf 'Captured log:\n' >&2
    cat "${LOG_FILE}" >&2
    exit 1
  fi
}

assert_line_in_file() {
  local expected="$1"
  local file_path="$2"
  if ! grep -Fqx "$expected" "${file_path}"; then
    printf 'Expected file line not found: %s\n' "$expected" >&2
    printf 'File content (%s):\n' "${file_path}" >&2
    cat "${file_path}" >&2
    exit 1
  fi
}

assert_contains_in_file() {
  local expected="$1"
  local file_path="$2"
  if ! grep -Fq "$expected" "${file_path}"; then
    printf 'Expected file content not found: %s\n' "$expected" >&2
    printf 'File content (%s):\n' "${file_path}" >&2
    cat "${file_path}" >&2
    exit 1
  fi
}

run_target() {
  local action="$1"
  shift
  seed_podman_state
  BACKEND_TEST_LOG_FILE="${LOG_FILE}" \
    BACKEND_TEST_PODMAN_STATE_FILE="${PODMAN_STATE_FILE}" \
    BACKEND_TEST_PODMAN_EXISTS_NAMES="${BACKEND_TEST_PODMAN_EXISTS_NAMES:-}" \
    BACKEND_TEST_PODMAN_EXISTS_RC="${BACKEND_TEST_PODMAN_EXISTS_RC:-}" \
    BACKEND_TEST_PODMAN_FAIL_STOP="${BACKEND_TEST_PODMAN_FAIL_STOP:-0}" \
    BACKEND_TEST_PODMAN_FAIL_RM="${BACKEND_TEST_PODMAN_FAIL_RM:-0}" \
    PATH="${FAKE_BIN}" \
    "${BASH_BIN}" "${TARGET_SCRIPT}" "$action" "$@"
}

run_raw() {
  seed_podman_state
  BACKEND_TEST_LOG_FILE="${LOG_FILE}" \
    BACKEND_TEST_PODMAN_STATE_FILE="${PODMAN_STATE_FILE}" \
    BACKEND_TEST_PODMAN_EXISTS_NAMES="${BACKEND_TEST_PODMAN_EXISTS_NAMES:-}" \
    BACKEND_TEST_PODMAN_EXISTS_RC="${BACKEND_TEST_PODMAN_EXISTS_RC:-}" \
    BACKEND_TEST_PODMAN_FAIL_STOP="${BACKEND_TEST_PODMAN_FAIL_STOP:-0}" \
    BACKEND_TEST_PODMAN_FAIL_RM="${BACKEND_TEST_PODMAN_FAIL_RM:-0}" \
    PATH="${FAKE_BIN}" \
    "${BASH_BIN}" "${TARGET_SCRIPT}" "$@"
}

run_init() {
  local backend="$1"
  local name="$2"
  BACKEND_TEST_LOG_FILE="${LOG_FILE}" \
    BACKEND_TEST_PODMAN_STATE_FILE="${PODMAN_STATE_FILE}" \
    BACKEND_TEST_PODMAN_EXISTS_NAMES="${BACKEND_TEST_PODMAN_EXISTS_NAMES:-}" \
    BACKEND_TEST_PODMAN_EXISTS_RC="${BACKEND_TEST_PODMAN_EXISTS_RC:-}" \
    BACKEND_TEST_PODMAN_FAIL_STOP="${BACKEND_TEST_PODMAN_FAIL_STOP:-0}" \
    BACKEND_TEST_PODMAN_FAIL_RM="${BACKEND_TEST_PODMAN_FAIL_RM:-0}" \
  CONTAINER_BACKEND="$backend" \
    PATH="${FAKE_BIN}" \
    HOME="${TMP_DIR}/home" \
    "${BASH_BIN}" "${INIT_SCRIPT}" "$name"
}

run_reset() {
  local backend="$1"
  local name="$2"
  local image="$3"
  seed_podman_state
  BACKEND_TEST_LOG_FILE="${LOG_FILE}" \
    BACKEND_TEST_PODMAN_STATE_FILE="${PODMAN_STATE_FILE}" \
    BACKEND_TEST_PODMAN_EXISTS_NAMES="${BACKEND_TEST_PODMAN_EXISTS_NAMES:-}" \
    BACKEND_TEST_PODMAN_EXISTS_RC="${BACKEND_TEST_PODMAN_EXISTS_RC:-}" \
    BACKEND_TEST_PODMAN_FAIL_STOP="${BACKEND_TEST_PODMAN_FAIL_STOP:-0}" \
    BACKEND_TEST_PODMAN_FAIL_RM="${BACKEND_TEST_PODMAN_FAIL_RM:-0}" \
  CONTAINER_BACKEND="$backend" \
    PATH="${FAKE_BIN}" \
    HOME="${TMP_DIR}/home" \
    "${BASH_BIN}" "${RESET_SCRIPT}" "$name" "$image"
}

prepare_container_init_fixture() {
  local home_dir="${TMP_DIR}/home"
  local app_dir="${home_dir}/.local/opt/firmaOK"
  mkdir -p "${app_dir}/System/Commons/links"
  cat >"${app_dir}/launcher_linux.com" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "${app_dir}/launcher_linux.com"
  : >"${app_dir}/System/Commons/links/icon.png"
}

run_container_init() {
  local backend="$1"
  local name="$2"

  prepare_container_init_fixture
  FIRMAOK_CONTAINER_BACKEND="${backend}" \
    FIRMAOK_CONTAINER_NAME="${name}" \
    HOME="${TMP_DIR}/home" \
    PATH="${FAKE_BIN}:${PATH}" \
    "${BASH_BIN}" "${CONTAINER_INIT_SCRIPT}"
}

seed_podman_state() {
  local state="${BACKEND_TEST_PODMAN_EXISTS_NAMES:-}"
  local item

  : >"${PODMAN_STATE_FILE}"
  if [[ -z "${state}" ]]; then
    return
  fi

  IFS=',' read -r -a items <<<"${state}"
  for item in "${items[@]}"; do
    if [[ -n "${item}" ]]; then
      printf '%s\n' "${item}" >>"${PODMAN_STATE_FILE}"
    fi
  done
}

expect_fail_contains() {
  local expected="$1"
  shift
  local output

  if output="$(run_raw "$@" 2>&1)"; then
    printf 'Expected command to fail: %s\n' "$*" >&2
    exit 1
  fi

  if [[ "${output}" != *"${expected}"* ]]; then
    printf 'Failure output did not match. expected="%s"\n' "${expected}" >&2
    printf 'actual:\n%s\n' "${output}" >&2
    exit 1
  fi
}

adapter_validate_routing() {
  setup_fake_env
  run_target validate toolbox tbx
  run_target validate distrobox dbx

  rm -f "${FAKE_BIN}/toolbox"
  expect_fail_contains 'Missing command: toolbox' validate toolbox tbx

  rm -f "${FAKE_BIN}/distrobox"
  expect_fail_contains 'Missing command: distrobox' validate distrobox dbx

  rm -f "${FAKE_BIN}/podman"
  expect_fail_contains 'Missing command: podman' validate toolbox tbx
  cleanup
}

adapter_create_routing() {
  setup_fake_env
  run_target create toolbox tbx img:test
  run_target create distrobox dbx img:test

  assert_in_log 'podman|container exists tbx'
  assert_in_log 'toolbox|create -c tbx -i img:test'
  assert_in_log 'podman|container exists dbx'
  assert_in_log 'distrobox|create --name dbx --image img:test'
  cleanup
}

adapter_create_exists_short_circuit() {
  setup_fake_env
  BACKEND_TEST_PODMAN_EXISTS_NAMES='tbx'
  run_target create toolbox tbx img:test

  assert_in_log 'podman|container exists tbx'
  assert_not_in_log 'toolbox|create -c tbx -i img:test'
  cleanup
}

adapter_create_exists_error() {
  setup_fake_env
  BACKEND_TEST_PODMAN_EXISTS_RC='125'

  if run_target create toolbox tbx img:test >/dev/null 2>&1; then
    printf 'Expected create to fail when podman exists errors\n' >&2
    exit 1
  fi

  assert_in_log 'podman|container exists tbx'
  assert_not_in_log 'toolbox|create -c tbx -i img:test'
  cleanup
}

adapter_enter_routing() {
  setup_fake_env
  run_target enter toolbox tbx
  run_target enter distrobox dbx

  assert_in_log 'toolbox|enter -c tbx'
  assert_in_log 'distrobox|enter -n dbx'
  cleanup
}

adapter_run_routing() {
  setup_fake_env
  run_target run toolbox tbx env A=1
  run_target run distrobox dbx sh -lc whoami

  assert_in_log 'toolbox|run -c tbx env A=1'
  assert_in_log 'distrobox|enter -n dbx -- sh -lc whoami'
  cleanup
}

adapter_reset_routing_non_exists() {
  setup_fake_env
  run_target reset toolbox tbx img:test

  assert_in_log 'podman|container exists tbx'
  assert_not_in_log 'podman|stop tbx'
  assert_not_in_log 'podman|rm tbx'
  assert_in_log 'toolbox|create -c tbx -i img:test'
  cleanup
}

adapter_reset_routing_exists() {
  setup_fake_env
  BACKEND_TEST_PODMAN_EXISTS_NAMES='tbx'
  run_target reset toolbox tbx img:test

  assert_in_log 'podman|container exists tbx'
  assert_in_log 'podman|stop tbx'
  assert_in_log 'podman|rm tbx'
  assert_in_log 'toolbox|create -c tbx -i img:test'
  cleanup
}

adapter_reset_stop_failure() {
  setup_fake_env
  BACKEND_TEST_PODMAN_EXISTS_NAMES='tbx'
  BACKEND_TEST_PODMAN_FAIL_STOP='1'

  run_target reset toolbox tbx img:test

  assert_in_log 'podman|stop tbx'
  assert_in_log 'podman|rm -f tbx'
  assert_in_log 'toolbox|create -c tbx -i img:test'
  cleanup
}

adapter_reset_stop_failure_force_rm_failure() {
  setup_fake_env
  BACKEND_TEST_PODMAN_EXISTS_NAMES='tbx'
  BACKEND_TEST_PODMAN_FAIL_STOP='1'
  BACKEND_TEST_PODMAN_FAIL_RM='1'

  if run_target reset toolbox tbx img:test >/dev/null 2>&1; then
    printf 'Expected reset to fail when force remove fails\n' >&2
    exit 1
  fi

  assert_in_log 'podman|stop tbx'
  assert_in_log 'podman|rm -f tbx'
  assert_not_in_log 'toolbox|create -c tbx -i img:test'
  cleanup
}

adapter_reset_exists_error() {
  setup_fake_env
  BACKEND_TEST_PODMAN_EXISTS_RC='125'

  if run_target reset toolbox tbx img:test >/dev/null 2>&1; then
    printf 'Expected reset to fail when podman exists errors\n' >&2
    exit 1
  fi

  assert_in_log 'podman|container exists tbx'
  assert_not_in_log 'podman|stop tbx'
  assert_not_in_log 'podman|rm tbx'
  assert_not_in_log 'toolbox|create -c tbx -i img:test'
  cleanup
}

adapter_invalid_backend() {
  setup_fake_env
  expect_fail_contains 'Unsupported backend: invalid-backend' create invalid-backend box img:test
  cleanup
}

cli_arg_contract() {
  setup_fake_env

  expect_fail_contains 'Usage: scripts/container-backend.sh <validate|create|enter|run|reset>'
  expect_fail_contains 'Usage: scripts/container-backend.sh <validate|create|enter|run|reset>' validate
  expect_fail_contains 'Usage: scripts/container-backend.sh <validate|create|enter|run|reset>' validate toolbox

  expect_fail_contains 'Usage: scripts/container-backend.sh create <toolbox|distrobox> <name> <image>' create toolbox tbx
  expect_fail_contains 'Usage: scripts/container-backend.sh create <toolbox|distrobox> <name> <image>' create toolbox tbx img:test extra

  expect_fail_contains 'Usage: scripts/container-backend.sh enter <toolbox|distrobox> <name>' enter toolbox tbx extra

  expect_fail_contains 'Usage: scripts/container-backend.sh run <toolbox|distrobox> <name> <command> [args...]' run toolbox tbx

  expect_fail_contains 'Usage: scripts/container-backend.sh reset <toolbox|distrobox> <name> <image>' reset toolbox tbx
  expect_fail_contains 'Usage: scripts/container-backend.sh reset <toolbox|distrobox> <name> <image>' reset toolbox tbx img:test extra

  expect_fail_contains 'Usage: scripts/container-backend.sh <validate|create|enter|run|reset>' validate toolbox tbx extra

  cleanup
}

init_routes_through_adapter() {
  setup_fake_env
  run_init distrobox tbx

  assert_in_log 'distrobox|enter -n tbx -- env FIRMAOK_TOOLBOX_NAME=tbx FIRMAOK_CONTAINER_NAME=tbx FIRMAOK_CONTAINER_BACKEND=distrobox /usr/local/bin/init-firmaok.sh'
  assert_not_in_log 'toolbox|run -c tbx env FIRMAOK_TOOLBOX_NAME=tbx /usr/local/bin/init-firmaok.sh'
  cleanup
}

reset_routes_through_adapter() {
  setup_fake_env
  run_reset distrobox tbx img:test

  assert_in_log 'podman|container exists tbx'
  assert_in_log 'distrobox|create --name tbx --image img:test'
  assert_not_in_log 'toolbox|create -c tbx -i img:test'
  cleanup
}

desktop_exec_distrobox() {
  setup_fake_env
  run_container_init distrobox dbx

  assert_line_in_file \
    'Exec=distrobox enter -n dbx -- firmaOK' \
    "${TMP_DIR}/home/.local/share/applications/firmaOk.desktop"
  cleanup
}

desktop_exec_toolbox() {
  setup_fake_env
  run_container_init toolbox tbx

  assert_line_in_file \
    'Exec=toolbox run -c tbx firmaOK' \
    "${TMP_DIR}/home/.local/share/applications/firmaOk.desktop"
  cleanup
}

uninstall_wording() {
  assert_contains_in_file 'Stai per disinstallare firmaOK dal container "%s".' "${ROOT_DIR}/scripts/uninstall.sh"
}

readme_backend_docs() {
  local readme_path="${ROOT_DIR}/README.md"

  assert_contains_in_file '## Backend container' "${readme_path}"
  assert_contains_in_file "Il backend predefinito e' il comportamento Toolbox." "${readme_path}"
  assert_contains_in_file 'In alternativa puoi usare Distrobox impostando `CONTAINER_BACKEND=distrobox`.' "${readme_path}"
  assert_contains_in_file 'CONTAINER_BACKEND=toolbox' "${readme_path}"
  assert_contains_in_file 'CONTAINER_NAME=firmaok-toolbox' "${readme_path}"
  assert_contains_in_file 'IMAGE=localhost/firmaok-toolbox:latest' "${readme_path}"
  assert_contains_in_file 'Nota: il ciclo di vita del container usa esclusivamente Podman.' "${readme_path}"
}

run_case() {
  local case_name="$1"
  case "$case_name" in
    adapter-validate-routing)
      adapter_validate_routing
      ;;
    adapter-create-routing)
      adapter_create_routing
      ;;
    adapter-create-exists-short-circuit)
      adapter_create_exists_short_circuit
      ;;
    adapter-create-exists-error)
      adapter_create_exists_error
      ;;
    adapter-enter-routing)
      adapter_enter_routing
      ;;
    adapter-run-routing)
      adapter_run_routing
      ;;
    adapter-reset-routing-non-exists)
      adapter_reset_routing_non_exists
      ;;
    adapter-reset-routing-exists)
      adapter_reset_routing_exists
      ;;
    adapter-reset-stop-failure)
      adapter_reset_stop_failure
      ;;
    adapter-reset-stop-failure-force-rm-failure)
      adapter_reset_stop_failure_force_rm_failure
      ;;
    adapter-reset-exists-error)
      adapter_reset_exists_error
      ;;
    adapter-invalid-backend)
      adapter_invalid_backend
      ;;
    cli-arg-contract)
      cli_arg_contract
      ;;
    init-routes-through-adapter)
      init_routes_through_adapter
      ;;
    reset-routes-through-adapter)
      reset_routes_through_adapter
      ;;
    desktop-exec-distrobox)
      desktop_exec_distrobox
      ;;
    desktop-exec-toolbox)
      desktop_exec_toolbox
      ;;
    uninstall-wording)
      uninstall_wording
      ;;
    readme-backend-docs)
      readme_backend_docs
      ;;
    *)
      printf 'Unknown test case: %s\n' "$case_name" >&2
      exit 1
      ;;
  esac
  printf '[OK] %s\n' "$case_name"
}

trap cleanup EXIT

if [[ "$#" -eq 0 ]]; then
  set -- \
    adapter-validate-routing \
    adapter-create-routing \
    adapter-create-exists-short-circuit \
    adapter-create-exists-error \
    adapter-enter-routing \
    adapter-run-routing \
    adapter-reset-routing-non-exists \
    adapter-reset-routing-exists \
    adapter-reset-stop-failure \
    adapter-reset-stop-failure-force-rm-failure \
    adapter-reset-exists-error \
    adapter-invalid-backend \
    cli-arg-contract \
    init-routes-through-adapter \
    reset-routes-through-adapter \
    desktop-exec-distrobox \
    desktop-exec-toolbox \
    uninstall-wording \
    readme-backend-docs
fi

for case_name in "$@"; do
  run_case "$case_name"
done
