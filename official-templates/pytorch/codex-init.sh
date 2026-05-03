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
    wrote_top_level = 0
    wrote_tui_status = 0
    seen_tui = 0
    section = "top"
  }

  function emit_top_level() {
    if (!wrote_top_level) {
      print "approval_policy = \"never\""
      print "sandbox_mode = \"danger-full-access\""
      print "default_permissions = \":danger-no-sandbox\""
      print "web_search = \"disabled\""
      wrote_top_level = 1
    }
  }

  function emit_tui_status() {
    if (!wrote_tui_status) {
      print "status_line = [\"model-with-reasoning\", \"context-remaining\", \"five-hour-limit\", \"weekly-limit\"]"
      wrote_tui_status = 1
    }
  }

  /^[[:space:]]*\[/ {
    if (section == "top") {
      emit_top_level()
    } else if (section == "tui") {
      emit_tui_status()
    }

    section = "other"
    if ($0 ~ /^[[:space:]]*\[tui\][[:space:]]*$/) {
      section = "tui"
      seen_tui = 1
    }

    print
    next
  }

  section == "top" && /^[[:space:]]*(approval_policy|sandbox_mode|default_permissions|web_search)[[:space:]]*=/ {
    next
  }

  section == "tui" && /^[[:space:]]*status_line[[:space:]]*=/ {
    next
  }

  { print }

  END {
    if (section == "top") {
      emit_top_level()
    } else if (section == "tui") {
      emit_tui_status()
    }

    if (!seen_tui) {
      print ""
      print "[tui]"
      emit_tui_status()
    }
  }
' "${config_file}" > "${tmp_file}"

mv "${tmp_file}" "${config_file}"
