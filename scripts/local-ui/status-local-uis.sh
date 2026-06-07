#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d .local-ui-pids ]]; then
  echo "No local UI port-forwards found"
else
  for pid_file in .local-ui-pids/*.pid; do
    [[ -e "$pid_file" ]] || continue

    name="$(basename "$pid_file" .pid)"
    pid="$(cat "$pid_file")"

    if kill -0 "$pid" 2>/dev/null; then
      echo "${name}: running with PID ${pid}"
    else
      echo "${name}: stopped"
    fi
  done
fi

echo
echo "Local UI URLs:"
echo "AIOps Dashboard: http://localhost:8088"
echo "Grafana:         http://localhost:3000"
echo "Prometheus:      http://localhost:9090"
echo "Alertmanager:    http://localhost:9093"
