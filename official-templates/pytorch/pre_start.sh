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
' &

run_update "claude update" "claude update" &

wait

echo "[pre_start] tool self-updates complete"
