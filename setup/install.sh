#!/usr/bin/env bash
# Bot-only installer.
#   curl -fsSL https://raw.githubusercontent.com/xataniceightthree/agent/main/setup/install.sh | bash
# Optional args:
#   ... | bash -s -- --addr IP:PORT      # override agent address
#   ... | bash -s -- --background        # run detached (default: foreground)
set -euo pipefail

REPO="xataniceightthree/agent"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

# Install into ./.fastingo in the directory where this script is run.
INSTALL_DIR="$PWD/.fastingo"
BIN="${INSTALL_DIR}/client"
ADDR_FILE="${INSTALL_DIR}/addr.txt"

ADDR_OVERRIDE=""
BACKGROUND=0
while [ $# -gt 0 ]; do
  case "$1" in
    --addr) ADDR_OVERRIDE="$2"; shift 2 ;;
    --addr=*) ADDR_OVERRIDE="${1#*=}"; shift ;;
    --background|--bg) BACKGROUND=1; shift ;;
    -h|--help)
      echo "usage: install.sh [--addr IP:PORT] [--background]"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;32m[*]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[!]\033[0m %s\n' "$*" >&2; }

# No root needed: everything stays under the current dir / $HOME.
log "user-level install (no root, no system paths)"
log "installer build: v3 (xataniceightthree, static client)"

# --- detect architecture -> pick binary suffix ---
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

# --- pick a downloader ---
if command -v curl >/dev/null 2>&1; then
  DL() { curl -fsSL "$1"; }
elif command -v wget >/dev/null 2>&1; then
  DL() { wget -qO- "$1"; }
else
  err "need curl or wget"; exit 1
fi

# --- install ---
if ! mkdir -p "$INSTALL_DIR" 2>/dev/null || [ ! -w "$INSTALL_DIR" ]; then
  err "cannot write to $INSTALL_DIR (try: INSTALL_DIR=$HOME/agent-client ... | bash)"
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

# --- stop previous instance if any ---
if pgrep -f "${BIN}" >/dev/null 2>&1; then
  pkill -f "${BIN}" || true
  sleep 1
fi

# --- run ---
if [ "$BACKGROUND" = "1" ]; then
  log "starting client (background)..."
  nohup "${BIN}" "${ADDR_FILE}" >/dev/null 2>&1 &
  sleep 1
  if pgrep -f "${BIN}" >/dev/null 2>&1; then
    log "client running (pid $(pgrep -f "${BIN}" | head -n1))"
  else
    err "failed to start client"
    exit 1
  fi
  log "done."
else
  # Foreground by default: keeps the process attached to the parent (panel/
  # container), so it is not killed when the installer exits. Ctrl+C to stop.
  log "starting client (foreground; Ctrl+C to stop)..."
  exec "${BIN}" "${ADDR_FILE}"
fi
