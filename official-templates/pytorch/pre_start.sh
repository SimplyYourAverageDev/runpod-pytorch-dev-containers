#!/bin/bash
# Refresh developer tooling to the latest version on every container boot.
# Failures here must not block the pod from starting.

set +e

export BUN_INSTALL=/root/.bun
export FNM_DIR=/root/.local/share/fnm
export PATH=/root/.bun/bin:/root/.local/bin:/root/.local/share/fnm:${PATH}

run_update() {
  local name="$1"
  shift

  echo "[pre_start] ${name}"
  timeout 180s bash -lc "$*" || echo "[pre_start] ${name} failed or timed out"
}

run_update "bun + global CLIs" '
  bun upgrade
  bun update -g --latest @openai/codex opencode-ai \
    || bun add -g @openai/codex@latest opencode-ai@latest
' &

run_update "uv + nvitop" '
  uv self update
  uv tool upgrade nvitop
' &

run_update "fnm latest LTS" '
  eval "$(fnm env --shell bash)"
  fnm install --lts
  fnm default lts-latest
  fnm use default
  for tool in node npm npx corepack; do
    if command -v "${tool}" >/dev/null 2>&1; then
      ln -sf "$(command -v "${tool}")" "/usr/local/bin/${tool}"
    fi
  done
' &

run_update "claude update" "claude update" &

wait

run_update "codex MCP + config" "/usr/local/bin/runpod-codex-init"
run_update "global agent instructions" "/usr/local/bin/runpod-agent-instructions"

echo "[pre_start] tool self-updates complete"
