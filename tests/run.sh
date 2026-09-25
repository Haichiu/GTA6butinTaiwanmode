#!/bin/sh
# Run the headless smoke tests with a hard time limit (a script parse error would otherwise hang Godot).
# Usage: tests/run.sh [level numbers...]    e.g. tests/run.sh 3 5
# --fixed-fps: same 60 Hz physics steps, but without waiting for wall-clock time.
cd "$(dirname "$0")/.." || exit 1
LIMIT=${SMOKE_LIMIT:-300}
# Refresh the global class cache so newly added class_name scripts resolve.
perl -e 'alarm shift; exec @ARGV' 120 godot --headless --path . --import >/dev/null 2>&1
perl -e 'alarm shift; exec @ARGV' "$LIMIT" godot --headless --fixed-fps 60 --path . res://tests/smoke.tscn -- "$@"
STATUS=$?
[ "$STATUS" -eq 142 ] && echo "SMOKE TIMEOUT after ${LIMIT}s"
exit $STATUS
