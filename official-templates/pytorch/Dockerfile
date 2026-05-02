ARG BASE_IMAGE=non-existing
FROM ${BASE_IMAGE}

ARG WHEEL_SRC
ARG TORCH

RUN python -m pip install --resume-retries 3 --no-cache-dir --upgrade ${TORCH} --index-url https://download.pytorch.org/whl/cu${WHEEL_SRC}

# Developer tooling: bun, fnm, codex, opencode, claude code, nvitop.
# uv is already provided by runpod/base (copied from ghcr.io/astral-sh/uv).
ENV BUN_INSTALL=/root/.bun
ENV FNM_DIR=/root/.local/share/fnm
ENV PATH=/root/.bun/bin:/root/.local/bin:/root/.local/share/fnm:${PATH}

# Bun (https://bun.com/docs/installation)
RUN curl -fsSL https://bun.com/install | bash

# fnm (https://github.com/Schniz/fnm) — skip-shell so we manage PATH ourselves
RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell \
 && eval "$(/root/.local/share/fnm/fnm env --shell bash)" \
 && fnm install --lts

# codex CLI + opencode via bun
RUN bun install -g @openai/codex opencode-ai

# Claude Code (native installer — recommended in 2026, supports `claude update`)
RUN curl -fsSL https://claude.ai/install.sh | bash

# nvitop via uv tool
RUN uv tool install nvitop

# Self-update tools on every container boot.
COPY pre_start.sh /pre_start.sh
RUN chmod +x /pre_start.sh
