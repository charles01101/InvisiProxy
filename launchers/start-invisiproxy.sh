#!/usr/bin/env bash
# InvisiProxy one-click launcher (Linux)
# Run: ./start-invisiproxy.sh   (or double-click, if your file manager allows it)
# Same behaviour as start-invisiproxy.command: boot the server, wait, open Firefox.

exec bash "$(cd "$(dirname "$0")" && pwd)/start-invisiproxy.command" "$@"
