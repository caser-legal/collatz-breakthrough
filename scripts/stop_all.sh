#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
RUNTIME=${COLLATZ_RUNTIME_DIR:-"${ROOT}/.runtime"}
PIDDIR=${RUNTIME}/pids

for name in gpu cpu; do
  pidfile=${PIDDIR}/${name}.pid
  [[ -r ${pidfile} ]] || continue
  read -r pid < "${pidfile}"
  if [[ ${pid} =~ ^[0-9]+$ ]] && kill -0 "${pid}" 2>/dev/null; then
    kill -TERM "${pid}"
    echo "Stopping ${name} client PID ${pid}."
  fi
  rm -f -- "${pidfile}"
done

