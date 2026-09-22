#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
RUNTIME=${COLLATZ_RUNTIME_DIR:-"${ROOT}/.runtime"}
SIEVES=${RUNTIME}/collatz-sieve
SIEVE_COMMIT=e5f0c264ba1f5f9c0a7d32a10c3aa61b225c70d1

for command_name in gcc git lz4 make; do
  command -v "${command_name}" >/dev/null || {
    echo "Missing dependency: ${command_name}" >&2
    exit 1
  }
done

mkdir -p -- "${RUNTIME}"
if [[ ! -d ${SIEVES}/.git ]]; then
  git clone --filter=blob:none --no-checkout \
    https://github.com/YOUR_GITHUB_USER/collatz-sieve.git "${SIEVES}"
  git -C "${SIEVES}" sparse-checkout init --no-cone
  git -C "${SIEVES}" sparse-checkout set \
    /unpack.sh /esieve-34.lut50.lz4 /h2esieve-24.lz4
fi
git -C "${SIEVES}" fetch --depth 1 origin "${SIEVE_COMMIT}"
git -C "${SIEVES}" checkout --detach "${SIEVE_COMMIT}"

make -C "${ROOT}/src/worker" clean all \
  CC=gcc USE_LIBGMP=1 USE_SIEVE=1 USE_PRECALC=1 \
  SIEVE_LOGSIZE=34 USE_SIEVE3=0 USE_SIEVE9=1 USE_LUT50=1
make -C "${ROOT}/src/gpuworker" clean all \
  CC=gcc TASK_UNITS=16 SIEVE_LOGSIZE=24 USE_SIEVE3=1
make -C "${ROOT}/src/mclient" clean all CC=gcc

rm -f -- "${ROOT}/src/worker/esieve-34.lut50.map" \
  "${ROOT}/src/gpuworker/esieve-24.map" \
  "${ROOT}/src/gpuworker/h2esieve-24.map"
(
  cd -- "${SIEVES}"
  ./unpack.sh esieve-34.lut50 "${ROOT}/src/worker"
  ./unpack.sh h2esieve-24 "${ROOT}/src/gpuworker"
)
mv -f -- "${ROOT}/src/gpuworker/h2esieve-24.map" \
  "${ROOT}/src/gpuworker/esieve-24.map"

echo "CPU and OpenCL GPU workers built successfully."
