#!/usr/bin/env bash
set -euo pipefail

TARGET="$1"
LOGFILE="$2"
SCRIPT_LOG="$3"
LOCKFILE="$4"
PIDFILE="$5"

log_status() {
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" >> "$SCRIPT_LOG"
}

mkdir -p "$(dirname "$LOGFILE")" "$(dirname "$SCRIPT_LOG")"

exec 9>"$LOCKFILE"
if ! flock -n 9; then
  log_status "SKIPPED" "PID $$: another instance already running (lock held on $LOCKFILE)"
  exit 1
fi

echo "$$" > "$PIDFILE"
log_status "STARTED" "PID $$ pinging $TARGET, logging to $LOGFILE"
  
trap 'rc=$?; log_status "STOPPED" "PID $$ exited (code $rc)"; rm -f "$PIDFILE"' EXIT

ping "$TARGET" | while IFS= read -r line; do
  printf '%s [PID %s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$$" "$line"
done >> "$LOGFILE"