#!/usr/bin/env bash
set -euo pipefail

mkdir -p .local-ui-pids .local-ui-logs

start_port_forward() {
  local name="$1"
  local namespace="$2"
  local target="$3"
  local ports="$4"

  local pid_file=".local-ui-pids/${name}.pid"
  local log_file=".local-ui-logs/${name}.log"

  if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
    echo "${name} already running with PID $(cat "$pid_file")"
    return
  fi

  echo "Starting ${name}: kubectl port-forward -n ${namespace} ${target} ${ports}"
  nohup kubectl port-forward -n "${namespace}" "${target}" "${ports}" > "${log_file}" 2>&1 &
  echo $! > "${pid_file}"

  sleep 2

  if kill -0 "$(cat "$pid_file")" 2>/dev/null; then
    echo "${name} started with PID $(cat "$pid_file")"
    echo "Log: ${log_file}"
  else
    echo "Failed to start ${name}. Check ${log_file}"
    exit 1
  fi
}

start_port_forward "aiops-dashboard" "capstone-aiops" "svc/aiops-dashboard" "8088:80"

echo
echo "Local UI URLs:"
echo "AIOps Dashboard: http://localhost:8088"
echo
echo "To stop:"
echo "./scripts/local-ui/stop-local-uis.sh"
