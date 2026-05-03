#!/bin/bash
# Configure Codex CLI defaults that should exist in every pod.

set -euo pipefail

export HOME="${HOME:-/root}"
export BUN_INSTALL="${BUN_INSTALL:-/root/.bun}"
export FNM_DIR="${FNM_DIR:-/root/.local/share/fnm}"
export PATH="${BUN_INSTALL}/bin:/root/.local/bin:${FNM_DIR}:${PATH}"

if [ -f /etc/profile.d/runpod-fnm.sh ]; then
  # shellcheck source=/dev/null
  . /etc/profile.d/runpod-fnm.sh
fi

config_dir="${HOME}/.codex"
config_file="${config_dir}/config.toml"

mkdir -p "${config_dir}"

codex mcp add exa --url https://mcp.exa.ai/mcp

tmp_file="$(mktemp)"
awk '
  BEGIN {
    wrote = 0
    in_top_level = 1
  }

  /^[[:space:]]*\[/ {
    if (!wrote) {
      print "web_search = \"disabled\""
      wrote = 1
    }
    in_top_level = 0
  }

  in_top_level && /^[[:space:]]*web_search[[:space:]]*=/ {
    if (!wrote) {
      print "web_search = \"disabled\""
      wrote = 1
    }
    next
  }

  { print }

  END {
    if (!wrote) {
      print "web_search = \"disabled\""
    }
  }
' "${config_file}" > "${tmp_file}"

mv "${tmp_file}" "${config_file}"
