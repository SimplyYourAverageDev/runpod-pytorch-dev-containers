#!/bin/bash
# Install shared global instructions for Codex, opencode, and Claude Code.

set -euo pipefail

export HOME="${HOME:-/root}"

detect_gpu_names() {
  if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null \
      | awk 'NF { sub(/^[[:space:]]+/, ""); sub(/[[:space:]]+$/, ""); if (!seen[$0]++) names = names (names ? ", " : "") $0 } END { if (names) print names }'
  fi
}

detect_ubuntu_version() {
  if [ -r /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    if [ -n "${PRETTY_NAME:-}" ]; then
      printf '%s\n' "${PRETTY_NAME}"
      return
    fi
  fi

  uname -sr
}

gpu_names="$(detect_gpu_names)"
if [ -z "${gpu_names}" ]; then
  gpu_names="unknown or unavailable at startup"
fi

os_version="$(detect_ubuntu_version)"

block_file="$(mktemp)"
cat > "${block_file}" <<EOF
<!-- BEGIN RUNPOD GLOBAL AGENT INSTRUCTIONS -->
## Environment

Local machine: GPU(s): ${gpu_names}; OS: ${os_version}.

## Tooling preference

Prefer modern, fast, ergonomic tooling over older defaults unless the project explicitly requires otherwise.

Examples:
- Python: prefer uv over pip, pip-tools, or virtualenv
- Node: prefer fnm over nvm
- JS/TS runtime/tooling: prefer Bun when compatible
- Data/scientific environments: prefer pixi/mamba over conda when appropriate

Apply this preference across package managers, runtimes, CLIs, linters, formatters, build tools, test runners, deployment tools, and environment managers.

If modern tooling fails, is incompatible, blocks expected functionality, or reduces reliability, automatically fall back to the traditional or more widely supported option. Correctness, reproducibility, maintainability, and working software take priority over tool preference.

## Search-first development

Use the Exa MCP server for web searches by default.

Default behavior: search first, then implement.

Search before implementing, configuring, upgrading, debugging, or recommending anything involving libraries, frameworks, SDKs, CLIs, build systems, package managers, language tooling, APIs, cloud services, deployment platforms, or developer workflows.

Treat software engineering knowledge as highly time-sensitive. Versions, APIs, defaults, deprecations, migration paths, and best practices can change within weeks or months.

Do not limit searches to a small set of obviously fast-moving tools. Assume most of the modern development ecosystem is fast-moving unless the task is purely local, timeless, or fully determined by files already present in the repository.

Before making technical decisions, verify current official documentation, release notes, changelogs, migration guides, issue discussions, and compatibility notes where relevant. Prefer primary sources: official docs, GitHub repositories, package registry pages, RFCs, and vendor documentation.

Search especially often for work involving React, Next.js, TypeScript, JavaScript, Node.js, Bun, Deno, Vite, Vitest, Tailwind CSS, Astro, SvelteKit, Nuxt, Python packaging, uv, Ruff, Pydantic, FastAPI, Django, Flask, Rust, Cargo, Tokio, Go, Kubernetes, Terraform, Docker, Compose, Postgres, Redis, Prisma, Drizzle, LangChain, LlamaIndex, OpenAI SDKs, Anthropic SDKs, Gemini SDKs, MCP tooling, browser automation, CI/CD systems, authentication libraries, payment APIs, and cloud provider SDKs.

After searching, use the newest stable, compatible approach supported by the project's constraints.

## Existing projects

When editing an existing project, inspect the repository before choosing tools. Check relevant files, including:

- package.json
- pyproject.toml
- uv.lock
- bun.lockb
- pnpm-lock.yaml
- package-lock.json
- Cargo.toml
- go.mod
- Dockerfile
- docker-compose.yml
- mise.toml
- .tool-versions
- Makefile
- README files
- CI configs
- existing scripts

Use the project's established conventions as the starting point, but do not follow them blindly. If there is a clearly more modern, faster, simpler, or better-optimized way to accomplish the task, prefer it when it is compatible with the project's requirements and does not introduce unnecessary migration risk.

Before changing conventions, verify current documentation and compatibility. Avoid large toolchain migrations unless they are directly useful for the task, explicitly requested, or clearly low-risk. For small improvements, prefer incremental adoption of better tooling or patterns over preserving older conventions solely for consistency.

If the repository pins versions or uses a specific toolchain, respect those constraints unless there is a clear reason to change them.

When search results conflict with existing project code, prefer the project's pinned versions and actual runtime behavior over generic documentation. Verify compatibility before applying changes.

## Communication

Briefly explain tool choices when they affect setup, commands, dependencies, or developer workflow. Include the specific tool, version, command, or documentation source used when relevant.
<!-- END RUNPOD GLOBAL AGENT INSTRUCTIONS -->
EOF

install_block() {
  local target_file="$1"
  local target_dir
  local stripped_file

  target_dir="$(dirname "${target_file}")"
  mkdir -p "${target_dir}"
  touch "${target_file}"

  stripped_file="$(mktemp)"
  awk '
    /<!-- BEGIN RUNPOD GLOBAL AGENT INSTRUCTIONS -->/ {
      skip = 1
      next
    }

    /<!-- END RUNPOD GLOBAL AGENT INSTRUCTIONS -->/ {
      skip = 0
      next
    }

    !skip {
      print
    }
  ' "${target_file}" > "${stripped_file}"

  {
    sed -e '${/^$/d;}' "${stripped_file}"
    if [ -s "${stripped_file}" ]; then
      printf '\n\n'
    fi
    cat "${block_file}"
    printf '\n'
  } > "${target_file}"

  rm -f "${stripped_file}"
}

install_block "${HOME}/.codex/AGENTS.md"
install_block "${HOME}/.config/opencode/AGENTS.md"
install_block "${HOME}/.claude/CLAUDE.md"

rm -f "${block_file}"
