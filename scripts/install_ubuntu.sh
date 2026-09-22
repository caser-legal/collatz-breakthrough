#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run this installer with sudo." >&2
  exit 1
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential ca-certificates clinfo git libgmp-dev lz4 \
  ocl-icd-opencl-dev

echo "Dependencies installed. The NVIDIA driver must expose the GPU to OpenCL."

