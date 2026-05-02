#!/bin/bash
# Refresh developer tooling to the latest version on every container boot.
# Failures here must not block the pod from starting.

set +e

export BUN_INSTALL=/root/.bun
export FNM_DIR=/root/.local/share/fnm
export PATH=/root/.bun/bin:/root/.local/bin:/root/.local/share/fnm:${PATH}

echo "[pre_start] bun upgrade"
bun upgrade

echo "[pre_start] uv self update"
uv self update

echo "[pre_start] fnm install --lts"
eval "$(fnm env --shell bash)"
fnm install --lts

echo "[pre_start] bun update -g --latest codex + opencode"
# bun update -g --latest is the documented form; fall back to a forced reinstall
# in case bun's global update path misses a package (oven-sh/bun#25585).
bun update -g --latest @openai/codex opencode-ai \
  || bun add -g @openai/codex@latest opencode-ai@latest

echo "[pre_start] claude update"
claude update

echo "[pre_start] uv tool upgrade nvitop"
uv tool upgrade nvitop

echo "[pre_start] tool self-updates complete"
