#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Ingo Ruhnke <grumbel@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# assemble.sh SRC OUT [SITE]
#
# Build the site in OUT from the page sources in SITE (default: this
# script's repository) and the builds in SRC (see fetch-builds.sh):
#   xanatoo.apk  xanatoo-r36s.zip  xanatoo-win32.zip  xanatoo-win64.zip
#   wasm/  versions/{android,r36s,win32,win64,wasm}.json
# Used by CI (builds from the release) and by flake.nix (builds from Nix).
set -euo pipefail

src=$1 out=$2
site=${3:-$(dirname "$(readlink -f "$0")")/..}
targets=(android r36s win64 win32 wasm)

for f in xanatoo.apk xanatoo-r36s.zip xanatoo-win32.zip xanatoo-win64.zip \
         wasm/index.html wasm/xanatoo.js wasm/xanatoo.wasm wasm/xanatoo.data; do
  test -s "$src/$f" || { echo "assemble: missing $src/$f" >&2; exit 1; }
done

mkdir -p "$out/downloads/r36s" "$out/downloads/versions" "$out/wasm"
cp -r "$site/images" "$out/images"
# Stable file names, so links never change (the version is on the page).
cp "$src/xanatoo.apk" "$out/downloads/xanatoo.apk"
# PortMaster expects the zip under the name its port.json gives.
cp "$src/xanatoo-r36s.zip" "$out/downloads/r36s/xanatoo.zip"
cp "$src/xanatoo-win32.zip" "$out/downloads/xanatoo-win32.zip"
cp "$src/xanatoo-win64.zip" "$out/downloads/xanatoo-win64.zip"
# The Emscripten index.html loads relative .js / .wasm / .data files.
cp -r "$src/wasm/." "$out/wasm/"

ver() { jq -r '.version // "unknown"' "$src/versions/$1.json"; }
for t in "${targets[@]}"; do
  cp "$src/versions/$t.json" "$out/downloads/versions/$t.json"
done

# The app's update check compares versionCode with its own (the commit
# time of the APK's build), so it must come from the APK's own build.
jq '{versionCode: (.lastModified // 1), versionName: .version}' \
  "$src/versions/android.json" > "$out/downloads/android-update.json"

# Headline version: the newest build (highest revCount) of any target.
newest=$(jq -rs 'max_by(.revCount // 0) | .version // "unknown"' "$src"/versions/*.json)
same=$(jq -rs 'map(.version) | unique | length' "$src"/versions/*.json)
if [ "$same" = 1 ]; then
  note="every file below is built from the same revision."
else
  note="each file below shows the revision it was built from; a build that failed keeps its previous version."
fi

sed -e "s|@version@|$newest|g" \
    -e "s|@version-note@|$note|g" \
    -e "s|@version-android@|$(ver android)|g" \
    -e "s|@version-r36s@|$(ver r36s)|g" \
    -e "s|@version-win64@|$(ver win64)|g" \
    -e "s|@version-win32@|$(ver win32)|g" \
    -e "s|@version-wasm@|$(ver wasm)|g" \
    "$site/index.html" > "$out/index.html"
if grep -q '@version' "$out/index.html"; then
  echo "assemble: unreplaced placeholder in index.html" >&2; exit 1
fi
chmod -R u+w "$out"
