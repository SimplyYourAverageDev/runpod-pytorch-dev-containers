# syntax=docker/dockerfile:1
ARG BASE_IMAGE=non-existing
FROM ${BASE_IMAGE}

ARG WHEEL_SRC
ARG TORCH

# Developer tooling: bun, fnm, codex, opencode, claude code, nvitop.
# uv is already provided by runpod/base (copied from ghcr.io/astral-sh/uv).
ENV BUN_INSTALL=/root/.bun
ENV FNM_DIR=/root/.local/share/fnm
ENV PATH=/root/.bun/bin:/root/.local/bin:/root/.local/share/fnm:${PATH}

# Bun (https://bun.com/docs/installation)
RUN curl -fsSL https://bun.com/install | bash

# fnm (https://github.com/Schniz/fnm) - skip-shell so we manage PATH ourselves.
RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell \
 && eval "$(/root/.local/share/fnm/fnm env --shell bash)" \
 && fnm install --lts \
 && fnm default lts-latest \
 && fnm use default \
 && for tool in node npm npx corepack; do \
      if command -v "${tool}" >/dev/null 2>&1; then \
        ln -sf "$(command -v "${tool}")" "/usr/local/bin/${tool}"; \
      fi; \
    done

# Make fnm-managed Node available in fresh SSH, terminal, and login shells.
COPY fnm-init.sh /etc/profile.d/runpod-fnm.sh
RUN chmod +x /etc/profile.d/runpod-fnm.sh \
 && touch /root/.bashrc /root/.profile /root/.zshrc \
 && { grep -qxF '. /etc/profile.d/runpod-fnm.sh' /root/.bashrc || echo '. /etc/profile.d/runpod-fnm.sh' >> /root/.bashrc; } \
 && { grep -qxF '. /etc/profile.d/runpod-fnm.sh' /root/.profile || echo '. /etc/profile.d/runpod-fnm.sh' >> /root/.profile; } \
 && { grep -qxF '. /etc/profile.d/runpod-fnm.sh' /root/.zshrc || echo '. /etc/profile.d/runpod-fnm.sh' >> /root/.zshrc; }

# codex CLI + opencode via bun
RUN bun install -g @openai/codex opencode-ai

COPY codex-init.sh /usr/local/bin/runpod-codex-init
RUN chmod +x /usr/local/bin/runpod-codex-init \
 && /usr/local/bin/runpod-codex-init

# Claude Code (native installer, supports `claude update`)
RUN curl -fsSL https://claude.ai/install.sh | bash

COPY agent-instructions.sh /usr/local/bin/runpod-agent-instructions
RUN chmod +x /usr/local/bin/runpod-agent-instructions \
 && /usr/local/bin/runpod-agent-instructions

# nvitop via uv tool
RUN --mount=type=cache,target=/root/.cache/uv uv tool install nvitop

RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --resume-retries 3 --upgrade ${TORCH} --index-url https://download.pytorch.org/whl/cu${WHEEL_SRC}

# Self-update tools on every container boot.
COPY pre_start.sh /pre_start.sh
RUN chmod +x /pre_start.sh
