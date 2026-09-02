#!/usr/bin/env bash
set -euo pipefail

bash scripts/check-godot.sh bash -c 'echo "All tests passed."'
for failure_case in \
  'exit 7' \
  'echo "SCRIPT ERROR: deliberate test failure" >&2' \
  'echo "ERROR: resource load failed"' \
  'printf "\033[31mERROR: colored error\033[0m\n"'; do
  if bash scripts/check-godot.sh bash -c "$failure_case"; then
    echo "Guard incorrectly accepted: $failure_case" >&2
    exit 1
  fi
done
if bash scripts/check-godot.sh; then
  echo "Guard must reject missing executable" >&2
  exit 1
fi
echo "Godot process guard tests passed."
