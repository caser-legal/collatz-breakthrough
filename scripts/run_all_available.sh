#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
RUNTIME=${COLLATZ_RUNTIME_DIR:-"${ROOT}/.runtime"}
SERVER=${SERVER_NAME:-collatz.example.edu}
PIDDIR=${RUNTIME}/pids
LOGDIR=${RUNTIME}/logs

mkdir -p -- "${PIDDIR}" "${LOGDIR}"

is_running() {
  local pidfile=$1 pid
  [[ -r ${pidfile} ]] || return 1
  read -r pid < "${pidfile}"
  [[ ${pid} =~ ^[0-9]+$ ]] && kill -0 "${pid}" 2>/dev/null
}

start_client() {
  local name=$1
  shift
  local pidfile=${PIDDIR}/${name}.pid
  local logfile=${LOGDIR}/${name}.log
  if is_running "${pidfile}"; then
    echo "${name} client already running as PID $(<"${pidfile}")."
    return
  fi
  (
    cd -- "${ROOT}/src/mclient"
    nohup env SERVER_NAME="${SERVER}" ./mclient "$@" \
      >>"${logfile}" 2>&1 </dev/null &
    echo "$!" >"${pidfile}"
  )
  sleep 1
  if ! is_running "${pidfile}"; then
    echo "${name} client failed to start; inspect ${logfile}." >&2
    exit 1
  fi
  echo "${name} client started as PID $(<"${pidfile}")."
}

if [[ ! -x ${ROOT}/src/worker/worker || ! -x ${ROOT}/src/gpuworker/gpuworker ||
      ! -x ${ROOT}/src/mclient/mclient ]]; then
  "${ROOT}/scripts/build_all.sh"
fi

cpu_total=$(nproc)
gpu_total=0
if command -v nvidia-smi >/dev/null 2>&1; then
  gpu_total=$(nvidia-smi --query-gpu=index --format=csv,noheader 2>/dev/null | wc -l)
fi

if (( gpu_total > 0 )); then
  command -v clinfo >/dev/null || {
    echo "NVIDIA GPUs found, but clinfo is missing; run scripts/install_ubuntu.sh." >&2
    exit 1
  }
  if ! clinfo -l 2>/dev/null | grep -q 'Device #'; then
    echo "NVIDIA GPUs found, but no OpenCL GPU device is exposed." >&2
    exit 1
  fi
fi

cpu_workers=$((cpu_total - gpu_total))
if (( cpu_workers < 1 )); then
  cpu_workers=1
fi

if (( gpu_total > 0 )); then
  start_client gpu -l -g -d -B "${gpu_total}"
  echo "${gpu_total}" >"${PIDDIR}/gpu.workers"
else
  echo "No NVIDIA GPU detected; starting CPU workers only."
fi
start_client cpu -l -B "${cpu_workers}"
echo "${cpu_workers}" >"${PIDDIR}/cpu.workers"

echo "Resources: ${cpu_workers}/${cpu_total} CPU workers, ${gpu_total} GPU workers."
echo "The clients run continuously with server-assigned work and no task-count cap."
"${ROOT}/scripts/status.sh"
