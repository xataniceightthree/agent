#!/usr/bin/env bash
# Foreground (hold) installer — keeps the client attached to the parent
# process (panel/container), so it stays alive while the panel runs it.
#   curl -fsSL https://raw.githubusercontent.com/xataniceightthree/agent/main/setup/installhold.sh | bash
# Optional:
#   ... | bash -s -- --addr IP:PORT
set -euo pipefail

REPO="xataniceightthree/agent"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

INSTALL_DIR="$PWD/.fastingo"
BIN="${INSTALL_DIR}/client"
ADDR_FILE="${INSTALL_DIR}/addr.txt"
PID_FILE="${INSTALL_DIR}/client.pid"

ADDR_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --addr) ADDR_OVERRIDE="$2"; shift 2 ;;
    --addr=*) ADDR_OVERRIDE="${1#*=}"; shift ;;
    -h|--help)
      echo "usage: installhold.sh [--addr IP:PORT]"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;32m[*]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[!]\033[0m %s\n' "$*" >&2; }

log "installer: hold mode (foreground)"

arch="$(uname -m)"
case "$arch" in
  x86_64|amd64)  SUFFIX="amd64" ;;
  aarch64|arm64) SUFFIX="arm64" ;;
  i386|i486|i586|i686) SUFFIX="386" ;;
  *) err "unsupported arch: $arch"; exit 1 ;;
esac
log "detected arch: $arch -> linux-${SUFFIX}"

BIN_URL="${RAW}/client/bin/client-linux-${SUFFIX}"
ADDR_URL="${RAW}/client/addr.txt"

if command -v curl >/dev/null 2>&1; then
  DL() { curl -fsSL "$1"; }
elif command -v wget >/dev/null 2>&1; then
  DL() { wget -qO- "$1"; }
else
  err "need curl or wget"; exit 1
fi

if ! mkdir -p "$INSTALL_DIR" 2>/dev/null || [ ! -w "$INSTALL_DIR" ]; then
  err "cannot write to $INSTALL_DIR"
  exit 1
fi
log "install dir: $INSTALL_DIR"

log "downloading client binary..."
DL "$BIN_URL" > "$BIN.tmp"
chmod +x "$BIN.tmp"
mv "$BIN.tmp" "$BIN"

if [ -n "$ADDR_OVERRIDE" ]; then
  printf '%s\n' "$ADDR_OVERRIDE" > "$ADDR_FILE"
else
  log "fetching addr.txt..."
  DL "$ADDR_URL" > "$ADDR_FILE"
fi
log "agent address: $(cat "$ADDR_FILE")"

# --- stop previous instance ---
if [ -f "$PID_FILE" ]; then
  old="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [ -n "$old" ] && kill -0 "$old" 2>/dev/null; then
    kill "$old" 2>/dev/null || true
    sleep 1
  fi
  rm -f "$PID_FILE"
fi
pkill -f "${BIN}" 2>/dev/null || true

# --- run in foreground (exec replaces this shell, stays attached) ---
log "starting client (foreground; Ctrl+C to stop)..."
printf '%s\n' "$$" > "$PID_FILE"
exec "${BIN}" "${ADDR_FILE}"
