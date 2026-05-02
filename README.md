# Runpod PyTorch Dev Containers

This repository contains Runpod-ready PyTorch Docker images with CUDA, JupyterLab, SSH, and developer tooling preinstalled. Built containers are published to [Docker Hub](https://hub.docker.com/r/youraveragedev/runpod-pytorch-dev).

## Container Requirements

### Dependencies

The following dependencies are required for all images for Runpod platform functionality.

- `nginx`: Required for proxying ports to the user.
- `openssh-server`: Required for SSH access to the container.
- `jupyterlab`: Required for JupyterLab access to the container.

### README

The PyTorch container folder has its own README.md file with the published image tags.

## Building Containers

This repository uses Docker Buildx with [bake files](https://docs.docker.com/build/bake/) to manage builds.

### Using the Bake Script

`./bake.sh` automatically combines shared version definitions with template specific bake files. 

Use it like this:

```bash
# Build the default targets for a template
./bake.sh pytorch

# Build a specific target or group of targets
./bake.sh pytorch pytorch-ubuntu2404-cu1281-torch280

# Build the default targets and load them to the local Docker daemon
./bake.sh pytorch --load
```

### Version Definitions

Version compatibility and build targets for CUDA, Ubuntu, and PyTorch are centralized in `official-templates/shared/versions.hcl`. This file is automatically included when building with the `bake.sh` script. When adding new versions or changing compatibility, modify this file.
