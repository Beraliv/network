# network

Scripts for continuously pinging a target host and logging the results, with
a watchdog that keeps the pinger alive.

## Files

- `ping.sh` — the worker. Pings a target host in a loop and appends
  timestamped output to a log file. Uses a lock file so only one instance can
  run at a time, and writes its own PID to a pid file while running.
- `monitor.sh` — the watchdog. Checks whether `ping.sh` is already running
  (via the lock file); if not, launches it in the background and detaches it
  from the current shell. Meant to be run periodically (e.g. from cron).

## Requirements

- bash
- `flock` and `ping` available on `PATH`
  - macOS does not ship `flock` (it's a Linux/util-linux tool) — install it
    first: `brew install flock`
- Write access to the log directory (default `/mnt/tank/configs/network/logs`)

## Setup

1. Make both scripts executable (already done in this repo, but after
   cloning/copying elsewhere):

   ```bash
   chmod +x monitor.sh ping.sh
   ```

2. `monitor.sh` defaults to launching the pinger from a fixed path:

   ```bash
   PINGER="/mnt/tank/configs/network/ping.sh"
   ```

   Deploy `ping.sh` at that path, or pass a different path as the sixth
   argument to `monitor.sh` (see below).

3. `monitor.sh` defaults `TARGET`, `LOGFILE`, `SCRIPT_LOG`, `LOCKFILE`, and
   `PIDFILE` to paths under `/mnt/tank/configs/network/logs`; pass them as
   positional arguments to override. `ping.sh` has no defaults of its own —
   it always receives all five from `monitor.sh` (or from you, when run
   directly).

## Running

### Running locally

Both scripts take `TARGET`, `LOGFILE`, `SCRIPT_LOG`, `LOCKFILE`, and
`PIDFILE` as positional arguments (in that order) — `ping.sh` has no
defaults, so all five are required. Point them at the `test/` folder instead
of `/mnt/tank/...` to try things out locally:

```bash
./ping.sh 1.1.1.1 test/ping_log.txt test/script_log.txt test/ping_log.txt.lock test/ping_log.txt.pid
```

Press Ctrl-C to stop; the trap on exit cleans up the pid file and logs the
stop.

### Via the watchdog

`monitor.sh` takes the same first five arguments plus a sixth for the
pinger's path:

```bash
./monitor.sh 1.1.1.1 test/ping_log.txt test/script_log.txt test/ping_log.txt.lock test/ping_log.txt.pid ./ping.sh
```

If no pinger is running (lock file free), it starts one in the background
and returns immediately. If one is already running, it logs that and exits
without starting a second instance.

### Via cron (recommended)

Run the watchdog on a schedule so the pinger gets relaunched automatically
if it ever dies:

```cron
* * * * * /mnt/tank/configs/network/scripts/monitor.sh
```

## Logs

- `ping_log.txt` — one line per ping reply, prefixed with timestamp and PID.
- `script_log.txt` — lifecycle events (`STARTED`, `STOPPED`, `SKIPPED`,
  `MONITOR`) from both scripts.

## Stopping

Kill the PID recorded in the pid file (`ping_log.txt.pid` by default):

```bash
kill "$(cat ping_log.txt.pid)"
```

The `ping.sh` exit trap removes the pid file and logs the stop.
