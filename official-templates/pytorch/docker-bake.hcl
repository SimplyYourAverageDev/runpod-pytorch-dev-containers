variable "IMAGE_NAMESPACE" {
  default = "youraveragedev"
}

variable "CUDA_TORCH_COMBINATIONS" {
  default = [
    { cuda_version = "12.8.1", torch = "2.8.0" },
    { cuda_version = "12.8.1", torch = "2.9.1" },
    { cuda_version = "13.0.0", torch = "2.9.1" },
  ]
}

variable "COMPATIBLE_BUILDS" {
  default = flatten([
    for combo in CUDA_TORCH_COMBINATIONS : [
      for cuda in CUDA_VERSIONS : [
        for ubuntu in UBUNTU_VERSIONS : {
          ubuntu_version = ubuntu.version
          ubuntu_name    = ubuntu.name
          cuda_version   = cuda.version
          cuda_code      = replace(cuda.version, ".", "")
          torch          = combo.torch
          torch_code     = replace(combo.torch, ".", "")
        } if cuda.version == combo.cuda_version && contains(cuda.ubuntu, ubuntu.version)
      ]
    ]
  ])
}

group "dev" {
  targets = ["pytorch-ubuntu2404-cu1281-torch280"]
}

group "default" {
  targets = [
    for build in COMPATIBLE_BUILDS:
      "pytorch-${build.ubuntu_name}-cu${replace(build.cuda_version, ".", "")}-torch${build.torch_code}"
  ]
}

target "pytorch-base" {
  context = "official-templates/pytorch"
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64"]
}

target "pytorch-matrix" {
  matrix = {
    build = COMPATIBLE_BUILDS
  }
  
  name = "pytorch-${build.ubuntu_name}-cu${build.cuda_code}-torch${build.torch_code}"
  
  inherits = ["pytorch-base"]
  
  args = {
    BASE_IMAGE = "runpod/pytorch:${RELEASE_VERSION}-cu${build.cuda_code}-torch${build.torch_code}-${build.ubuntu_name}"
  }
  
  tags = [
    "${IMAGE_NAMESPACE}/runpod-pytorch-dev:${RELEASE_VERSION}${RELEASE_SUFFIX}-cu${build.cuda_code}-torch${build.torch_code}-${build.ubuntu_name}",
  ]

  cache-from = [
    "type=gha,scope=pytorch-${build.cuda_code}-torch${build.torch_code}",
  ]

  cache-to = [
    "type=gha,scope=pytorch-${build.cuda_code}-torch${build.torch_code},mode=max",
  ]
}
