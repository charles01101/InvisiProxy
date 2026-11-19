#!/usr/bin/env bash
# InvisiProxy one-click launcher (macOS / Linux)
# Double-click on macOS, or run: ./start-invisiproxy.command
# Starts the local InvisiProxy LTS server, waits for it, then opens Firefox.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="${INVISIPROXY_DIR:-$SCRIPT_DIR}"
[ -f "$ROOT/package.json" ] || ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

say() { printf '\033[1m[InvisiProxy]\033[0m %s\n' "$*"; }
fail() {
  printf '\033[1;31m[InvisiProxy]\033[0m %s\n' "$*" >&2
  printf '\nPress Enter to close…\n'
  read -r _ || true
  exit 1
}

cd "$ROOT" || fail "Cannot enter the InvisiProxy folder: $ROOT"
[ -f ecosystem.config.js ] || fail "This is not the InvisiProxy repo (no ecosystem.config.js in $ROOT)."

if ! command -v node >/dev/null 2>&1; then
  fail "Node.js is not installed. Install the LTS build from https://nodejs.org/ then run this again."
fi

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
[ "$NODE_MAJOR" -ge 20 ] 2>/dev/null || say "Warning: Node $(node -v) detected; InvisiProxy targets Node 20.x."

PORT="$(sed -n 's/.*PORT: *\([0-9][0-9]*\).*/\1/p' ecosystem.config.js | head -n 1)"
PORT="${PORT:-8080}"
URL="http://localhost:$PORT"

open_firefox() {
  if command -v firefox >/dev/null 2>&1; then
    firefox "$URL" >/dev/null 2>&1 &
  elif command -v firefox-esr >/dev/null 2>&1; then
    firefox-esr "$URL" >/dev/null 2>&1 &
  elif [ "$(uname -s)" = "Darwin" ]; then
    open -a Firefox "$URL" >/dev/null 2>&1 || open "$URL" >/dev/null 2>&1
  else
    xdg-open "$URL" >/dev/null 2>&1 || say "Open $URL in Firefox manually."
  fi
}

is_up() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsS --max-time 2 -o /dev/null "$URL/manifest.json" 2>/dev/null
  else
    node -e 'const h=require("http");const r=h.get(process.argv[1],x=>{x.resume();process.exit(x.statusCode<500?0:1)});r.on("error",()=>process.exit(1));r.setTimeout(2000,()=>{r.destroy();process.exit(1)})' "$URL/manifest.json"
  fi
}

if is_up; then
  say "Server already running at $URL — opening Firefox."
  open_firefox
  exit 0
fi

if [ ! -d node_modules ] || [ ! -d lib/rammerhead/node_modules ]; then
  say "First run: installing dependencies (this takes a few minutes)…"
  npm run fresh-install || fail "Dependency install failed. See the output above."
fi

say "Starting server on port $PORT…"
npm start || fail "Server start failed. Run 'npm run manual-start' in $ROOT to see the error."

say "Waiting for the server to come up…"
TRIES=0
while [ "$TRIES" -lt 120 ]; do
  if is_up; then
    say "Ready at $URL — opening Firefox."
    open_firefox
    exit 0
  fi
  TRIES=$((TRIES + 1))
  sleep 1
done

say "The server did not answer within 2 minutes."
say "Check the log with: npx pm2 logs InvisiProxyLTS"
say "Then open $URL manually."
printf '\nPress Enter to close…\n'
read -r _ || true
exit 1
