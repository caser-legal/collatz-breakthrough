#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
RUNTIME=${COLLATZ_RUNTIME_DIR:-"${ROOT}/.runtime"}
PIDDIR=${RUNTIME}/pids
LOGDIR=${RUNTIME}/logs
WATCH=0
[[ ${1:-} == --watch ]] && WATCH=1

show_status() {
  date -u '+status_utc=%Y-%m-%dT%H:%M:%SZ'
  for name in gpu cpu; do
    local pidfile=${PIDDIR}/${name}.pid
    local workersfile=${PIDDIR}/${name}.workers
    local logfile=${LOGDIR}/${name}.log
    local pid=none state=stopped returned=0 workers=0 work_units=0
    if [[ -r ${pidfile} ]]; then
      read -r pid < "${pidfile}"
      if [[ ${pid} =~ ^[0-9]+$ ]] && kill -0 "${pid}" 2>/dev/null; then
        state=running
      fi
    fi
    if [[ -r ${logfile} ]]; then
      returned=$(grep -c 'all assignments returned' "${logfile}" || true)
    fi
    [[ -r ${workersfile} ]] && read -r workers < "${workersfile}"
    work_units=$((returned * workers))
    echo "${name}: state=${state} pid=${pid} workers=${workers} returned_batches=${returned}"
    echo "${name}: completed_work_units=${work_units} integers_per_work_unit=2^40"
    [[ -r ${logfile} ]] && tail -n 2 "${logfile}"
  done
}

while :; do
  show_status
  (( WATCH )) || break
  sleep 2
done
