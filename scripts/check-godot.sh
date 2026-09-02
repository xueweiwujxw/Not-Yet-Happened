#!/usr/bin/env bash
# Godot can report a script error and still exit zero. Never treat that as a pass.
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: bash scripts/check-godot.sh <executable> [arguments...]" >&2
  exit 2
fi

check_log=$(mktemp)
trap 'rm -f "$check_log"' EXIT
"$@" 2>&1 | tee "$check_log"
if grep -Eq '(SCRIPT ERROR|ERROR):' "$check_log"; then
  echo "Godot reported an error despite a successful process exit." >&2
  exit 1
fi
