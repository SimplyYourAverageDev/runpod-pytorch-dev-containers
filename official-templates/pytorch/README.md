### Runpod PyTorch

**PyTorch-optimized images for deep learning workflows.**

Built on Runpod CUDA base images, these containers provide pre-configured PyTorch and CUDA combinations for immediate deep learning development. Skip the compatibility guesswork and setup time: just run, and start training.

### What's included
- **Version matched**: PyTorch and CUDA combinations tested for optimal compatibility.
- **Zero setup**: PyTorch ready to import immediately, no additional installs required.
- **GPU accelerated**: Full CUDA support enabled for immediate deep learning acceleration.
- **Production ready**: Built on stable CUDA base images with complete development toolchain.
- **Developer tooling**: [bun](https://bun.com), [uv](https://docs.astral.sh/uv/), [fnm](https://github.com/Schniz/fnm),
  [Claude Code](https://github.com/anthropics/claude-code), [Codex CLI](https://github.com/openai/codex),
  [opencode](https://opencode.ai), and [nvitop](https://github.com/XuehaiPan/nvitop) preinstalled and
  self-updated on every pod boot.

### Available configurations
- **PyTorch**: 2.8.0 and 2.9.1
- **CUDA**: 12.8.1 and 13.0.0
- **Ubuntu**: 24.04 (Noble)

Focus on your models, not your environment setup.

<div class="base-images">

## Available PyTorch Images

### CUDA 12.8.1:
- Torch 2.8.0:
  - Ubuntu 24.04: `youraveragedev/runpod-pytorch-dev:1.0.3-cu1281-torch280-ubuntu2404`
- Torch 2.9.1:
  - Ubuntu 24.04: `youraveragedev/runpod-pytorch-dev:1.0.3-cu1281-torch291-ubuntu2404`

### CUDA 13.0.0:
- Torch 2.9.1:
  - Ubuntu 24.04: `youraveragedev/runpod-pytorch-dev:1.0.3-cu1300-torch291-ubuntu2404`
</div>
