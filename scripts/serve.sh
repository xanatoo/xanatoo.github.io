#!/usr/bin/env bash
# Serve the xanatoo site (PKG, default: cwd) on 127.0.0.1:$XANATOO_SITE_PORT (8765).
set -euo pipefail
[ -n "${PKG:-}" ] && cd "$PKG"
port="${XANATOO_SITE_PORT:-8765}"
echo "Serving xanatoo site at http://127.0.0.1:${port}/  (Ctrl-C to stop)"
exec python3 -m http.server "$port" --bind 127.0.0.1
