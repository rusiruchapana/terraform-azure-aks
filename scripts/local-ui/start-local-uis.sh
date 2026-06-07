#!/usr/bin/env bash
set -euo pipefail

mkdir -p .local-ui-pids .local-ui-logs

start_port_forward() {
  local name="$1"
  local namespace="$2"
  local target="$3"
  local ports="$4"

  local local_port="${ports%%:*}"
  local pid_file=".local-ui-pids/${name}.pid"
  local log_file=".local-ui-logs/${name}.log"

  if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
    echo "${name} already running with PID $(cat "$pid_file")"
    return
  fi

  if lsof -i ":${local_port}" >/dev/null 2>&1; then
    echo "Port ${local_port} is already in use. Cannot start ${name}."
    echo "Run: lsof -i :${local_port}"
    exit 1
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
start_port_forward "grafana" "monitoring" "svc/monitoring-grafana" "3000:80"
start_port_forward "prometheus" "monitoring" "svc/monitoring-kube-prometheus-prometheus" "9090:9090"
start_port_forward "alertmanager" "monitoring" "svc/monitoring-kube-prometheus-alertmanager" "9093:9093"

echo
echo "Local UI URLs:"
echo "AIOps Dashboard: http://localhost:8088"
echo "Grafana:         http://localhost:3000"
echo "Prometheus:      http://localhost:9090"
echo "Alertmanager:    http://localhost:9093"
echo
echo "Status:"
echo "./scripts/local-ui/status-local-uis.sh"
echo
echo "Stop:"
echo "./scripts/local-ui/stop-local-uis.sh"
