#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d .local-ui-pids ]]; then
  echo "No local UI port-forwards found"
  exit 0
fi

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
