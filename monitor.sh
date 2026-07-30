#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-1.1.1.1}"
LOGFILE="${2:-/mnt/tank/configs/network/logs/ping_log.txt}"
SCRIPT_LOG="${3:-/mnt/tank/configs/network/logs/script_log.txt}"
LOCKFILE="${4:-${LOGFILE}.lock}"
PIDFILE="${5:-${LOGFILE}.pid}"
PINGER="${6:-/mnt/tank/configs/network/ping.sh}"

log_status() {
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" >> "$SCRIPT_LOG"
}

mkdir -p "$(dirname "$LOGFILE")" "$(dirname "$SCRIPT_LOG")"

if flock -n "$LOCKFILE" true 2>/dev/null; then
  nohup "$PINGER" "$TARGET" "$LOGFILE" "$SCRIPT_LOG" "$LOCKFILE" "$PIDFILE" >/dev/null 2>&1 &
  disown
  log_status "MONITOR" "no pinger running, launched new instance (PID $!)"
else
  running_pid="$(cat "$PIDFILE" 2>/dev/null || echo unknown)"
  log_status "MONITOR" "pinger already running (PID $running_pid), skipping launch"
fi