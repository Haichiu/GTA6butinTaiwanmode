#!/bin/bash
# Render review screenshots in a small window in the bottom-right corner of the screen, and hand
# focus straight back to whatever app was in front, so it doesn't get in the user's way.
#   tests/shot.sh <out_dir> [name_prefix]      (screenshots)
#   SCENE=res://tests/flow.tscn tests/shot.sh <out_dir>
cd "$(dirname "$0")/.."
W=800; H=450
read -r _ _ SW SH <<<"$(osascript -e 'tell application "Finder" to get bounds of window of desktop' | tr -d ',')"
FRONT=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)
perl -e 'alarm 300; exec @ARGV' godot --path . --resolution ${W}x${H} --position $((SW - W)),$((SH - H)) \
	"${SCENE:-res://tests/shot.tscn}" -- "$@" &
PID=$!
if [ -n "$FRONT" ]; then
	sleep 1.5
	osascript -e "tell application \"$FRONT\" to activate" >/dev/null 2>&1
fi
wait $PID
