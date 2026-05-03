#!/bin/bash
# Refresh developer tooling while keeping pod readiness honest.
# Update attempts are best effort, but the baked tools must still verify.

set -uo pipefail

export HOME="${HOME:-/root}"
export BUN_INSTALL=/root/.bun
export FNM_DIR=/root/.local/share/fnm
export PATH=/root/.bun/bin:/root/.local/bin:/root/.local/share/fnm:${PATH}

UPDATE_TIMEOUT="${RUNPOD_PRE_START_UPDATE_TIMEOUT:-180s}"
VERIFY_TIMEOUT="${RUNPOD_PRE_START_VERIFY_TIMEOUT:-30s}"
LOG_DIR="$(mktemp -d /tmp/runpod-pre-start.XXXXXX)"

declare -a TASK_PIDS=()
declare -a TASK_NAMES=()

log_name() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_'
}

run_step() {
  local name="$1"
  local command="$2"
  local log_file="${LOG_DIR}/$(log_name "${name}").log"

  echo "[pre_start] ${name}"

  if timeout "${UPDATE_TIMEOUT}" bash -o pipefail -lc "${command}" >"${log_file}" 2>&1; then
    echo "[pre_start] ${name} complete"
    return 0
  fi

  local status=$?
  echo "[pre_start] ${name} failed or timed out (${status})"
  tail -n 80 "${log_file}" || true
  return "${status}"
}

register_task() {
  local name="$1"
  local pid="$2"

  TASK_NAMES+=("${name}")
  TASK_PIDS+=("${pid}")
}

start_task() {
  local name="$1"
  local command="$2"

  (
    run_step "${name}" "${command}"
  ) &
  register_task "${name}" "$!"
}

start_bun_codex_task() {
  (
    local status=0

    run_step "bun + global CLIs" '
      status=0
      bun upgrade || status=$?
      bun add -g @openai/codex@latest opencode-ai@latest || status=$?
      exit "${status}"
    ' || status=$?

    run_step "codex MCP + config" "/usr/local/bin/runpod-codex-init" || status=$?

    exit "${status}"
  ) &
  register_task "bun/codex" "$!"
}

wait_for_tasks() {
  local failed=0
  local index

  for index in "${!TASK_PIDS[@]}"; do
    if ! wait "${TASK_PIDS[${index}]}"; then
      echo "[pre_start] ${TASK_NAMES[${index}]} finished with warnings"
      failed=$((failed + 1))
    fi
  done

  if [ "${failed}" -gt 0 ]; then
    echo "[pre_start] ${failed} update task(s) failed; verifying baked tools before continuing"
  fi
}

refresh_node_shims() {
  if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --shell bash)" || true
    fnm use default >/dev/null 2>&1 || true
  fi

  for tool in node npm npx corepack; do
    if command -v "${tool}" >/dev/null 2>&1; then
      ln -sf "$(command -v "${tool}")" "/usr/local/bin/${tool}" || true
    fi
  done
}

verify_command() {
  local command="$1"
  shift

  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "[pre_start] verify failed: ${command} is not on PATH"
    return 1
  fi

  local log_file="${LOG_DIR}/verify-$(log_name "${command}").log"
  if ! timeout "${VERIFY_TIMEOUT}" "${command}" "$@" >"${log_file}" 2>&1; then
    echo "[pre_start] verify failed: ${command} $*"
    tail -n 40 "${log_file}" || true
    return 1
  fi

  printf '[pre_start] verified %s: ' "${command}"
  head -n 1 "${log_file}" || true
}

verify_file_contains() {
  local file="$1"
  local pattern="$2"

  if [ ! -f "${file}" ] || ! grep -qF "${pattern}" "${file}"; then
    echo "[pre_start] verify failed: ${file} is missing expected configuration"
    return 1
  fi
}

verify_ready() {
  local failures=0

  refresh_node_shims

  verify_command bun --version || failures=$((failures + 1))
  verify_command fnm --version || failures=$((failures + 1))
  verify_command node --version || failures=$((failures + 1))
  verify_command npm --version || failures=$((failures + 1))
  verify_command npx --version || failures=$((failures + 1))
  verify_command corepack --version || failures=$((failures + 1))
  verify_command codex --version || failures=$((failures + 1))
  verify_command opencode --version || failures=$((failures + 1))
  verify_command claude --version || failures=$((failures + 1))
  verify_command uv --version || failures=$((failures + 1))
  verify_command nvitop --version || failures=$((failures + 1))

  verify_file_contains "${HOME}/.codex/config.toml" 'web_search = "disabled"' || failures=$((failures + 1))
  verify_file_contains "${HOME}/.codex/AGENTS.md" "BEGIN RUNPOD GLOBAL AGENT INSTRUCTIONS" || failures=$((failures + 1))
  verify_file_contains "${HOME}/.config/opencode/AGENTS.md" "BEGIN RUNPOD GLOBAL AGENT INSTRUCTIONS" || failures=$((failures + 1))
  verify_file_contains "${HOME}/.claude/CLAUDE.md" "BEGIN RUNPOD GLOBAL AGENT INSTRUCTIONS" || failures=$((failures + 1))

  if [ "${failures}" -gt 0 ]; then
    echo "[pre_start] readiness verification failed with ${failures} issue(s)"
    return 1
  fi
}

start_bun_codex_task

start_task "uv + nvitop" '
  status=0
  uv self update || status=$?
  uv tool upgrade nvitop || uv tool install nvitop || status=$?
  exit "${status}"
'

start_task "fnm latest LTS" '
  set -e
  eval "$(fnm env --shell bash)"
  fnm install --lts --use --progress=never
  fnm default "$(fnm current)"
  fnm use default
  for tool in node npm npx corepack; do
    if command -v "${tool}" >/dev/null 2>&1; then
      ln -sf "$(command -v "${tool}")" "/usr/local/bin/${tool}"
    fi
  done
'

start_task "claude update" "claude update"
start_task "global agent instructions" "/usr/local/bin/runpod-agent-instructions"

wait_for_tasks
verify_ready

echo "[pre_start] tool self-updates complete"
