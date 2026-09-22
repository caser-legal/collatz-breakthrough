#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

for script in "${ROOT}"/scripts/{install_ubuntu,build_all,run_all_available,status,stop_all}.sh; do
  bash -n "${script}"
done

grep -q 'nproc' "${ROOT}/scripts/run_all_available.sh"
grep -q 'nvidia-smi --query-gpu=index' "${ROOT}/scripts/run_all_available.sh"
grep -q 'clinfo -l' "${ROOT}/scripts/run_all_available.sh"
grep -q 'sleep 2' "${ROOT}/scripts/status.sh"
grep -q 'while (!quit)' "${ROOT}/src/mclient/mclient.c"

echo "deployment checks passed"
