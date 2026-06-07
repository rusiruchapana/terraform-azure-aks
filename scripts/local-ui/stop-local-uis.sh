#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d .local-ui-pids ]]; then
  echo "No .local-ui-pids directory found"
  exit 0
fi

for pid_file in .local-ui-pids/*.pid; do
  [[ -e "$pid_file" ]] || continue

  name="$(basename "$pid_file" .pid)"
  pid="$(cat "$pid_file")"

  if kill -0 "$pid" 2>/dev/null; then
    echo "Stopping ${name} with PID ${pid}"
    kill "$pid"
  else
    echo "${name} is not running"
  fi

  rm -f "$pid_file"
done

echo "Local UI port-forwards stopped"
