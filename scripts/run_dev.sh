#!/usr/bin/env bash
#
# Runs the app against the API on this machine, working out the right host
# automatically.
#
#   ./scripts/run_dev.sh                 # first available device
#   ./scripts/run_dev.sh -d <device-id>  # a specific one (flutter devices)
#
# Why this exists: the app runs on the phone, not on your Mac, so it cannot
# discover your Mac's address at runtime. This script resolves it here and
# bakes it in with --dart-define.
set -euo pipefail

PORT=3002   # APP_API_PORT in bookslane-api

# The Mac's current Wi-Fi/Ethernet address. Changes when you switch networks,
# which is exactly why it is read fresh on every run.
lan_ip() {
  ipconfig getifaddr en0 2>/dev/null \
    || ipconfig getifaddr en1 2>/dev/null \
    || echo ""
}

IP="$(lan_ip)"

if [[ -z "$IP" ]]; then
  echo "!! No LAN address found (not on Wi-Fi?). Falling back to defaults."
  exec flutter run "$@"
fi

# On a USB-attached Android device, adb can tunnel the port instead: the
# device's own localhost:PORT is forwarded to this machine. That survives
# network changes and needs no IP at all, so prefer it when it is available.
if command -v adb >/dev/null 2>&1; then
  if adb devices | grep -qw "device"; then
    if adb reverse "tcp:$PORT" "tcp:$PORT" >/dev/null 2>&1; then
      echo ">> adb reverse active: device localhost:$PORT -> this machine"
      exec flutter run --dart-define=DEV_HOST=localhost "$@"
    fi
  fi
fi

echo ">> API host: $IP:$PORT"
exec flutter run --dart-define="DEV_HOST=$IP" "$@"
