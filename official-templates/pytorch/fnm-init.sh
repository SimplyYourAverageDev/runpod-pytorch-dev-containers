#!/bin/sh

export BUN_INSTALL="${BUN_INSTALL:-/root/.bun}"
export FNM_DIR="${FNM_DIR:-/root/.local/share/fnm}"
export PATH="${BUN_INSTALL}/bin:/root/.local/bin:${FNM_DIR}:${PATH}"

if command -v fnm >/dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$(fnm env --shell zsh)"
  else
    eval "$(fnm env --shell bash)"
  fi

  fnm use default >/dev/null 2>&1 || true
fi
