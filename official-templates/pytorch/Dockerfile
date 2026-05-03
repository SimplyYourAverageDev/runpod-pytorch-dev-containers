# syntax=docker/dockerfile:1
ARG BASE_IMAGE=non-existing
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Developer tooling: bun, fnm, codex, opencode, claude code, nvitop.
# PyTorch, CUDA, Jupyter, SSH, nginx, and uv are provided by runpod/pytorch.
ENV BUN_INSTALL=/root/.bun
ENV FNM_DIR=/root/.local/share/fnm
ENV PATH=/root/.bun/bin:/root/.local/bin:/root/.local/share/fnm:${PATH}

# Bun (https://bun.com/docs/installation)
RUN curl -fsSL https://bun.com/install | bash

# fnm (https://github.com/Schniz/fnm) - skip-shell so we manage PATH ourselves.
RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell \
 && eval "$(/root/.local/share/fnm/fnm env --shell bash)" \
 && fnm install --lts --use --progress=never \
 && fnm default "$(fnm current)" \
 && fnm use default \
 && for tool in node npm npx corepack; do \
      if command -v "${tool}" >/dev/null 2>&1; then \
        ln -sf "$(command -v "${tool}")" "/usr/local/bin/${tool}"; \
      fi; \
    done

# Make fnm-managed Node available in fresh SSH, terminal, and login shells.
COPY --link --chmod=755 fnm-init.sh /etc/profile.d/runpod-fnm.sh
RUN touch /root/.bashrc /root/.profile /root/.zshrc \
 && { grep -qxF '. /etc/profile.d/runpod-fnm.sh' /root/.bashrc || echo '. /etc/profile.d/runpod-fnm.sh' >> /root/.bashrc; } \
 && { grep -qxF '. /etc/profile.d/runpod-fnm.sh' /root/.profile || echo '. /etc/profile.d/runpod-fnm.sh' >> /root/.profile; } \
 && { grep -qxF '. /etc/profile.d/runpod-fnm.sh' /root/.zshrc || echo '. /etc/profile.d/runpod-fnm.sh' >> /root/.zshrc; }

# codex CLI + opencode via bun
RUN --mount=type=cache,target=/root/.bun/install/cache \
    bun add -g @openai/codex@latest opencode-ai@latest

COPY --link --chmod=755 codex-init.sh /usr/local/bin/runpod-codex-init
RUN /usr/local/bin/runpod-codex-init

# Claude Code (native installer, supports `claude update`)
RUN curl -fsSL https://claude.ai/install.sh | bash

COPY --link --chmod=755 agent-instructions.sh /usr/local/bin/runpod-agent-instructions
RUN /usr/local/bin/runpod-agent-instructions

# nvitop via uv tool
RUN --mount=type=cache,target=/root/.cache/uv uv tool install nvitop

# Self-update tools on every container boot.
COPY --link --chmod=755 pre_start.sh /pre_start.sh
