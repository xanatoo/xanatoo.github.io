#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Ingo Ruhnke <grumbel@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# fetch-builds.sh DIR
#
# Fill DIR with the newest build of every target, in the layout
# assemble.sh reads: xanatoo.apk, xanatoo-r36s.zip, xanatoo-win{32,64}.zip,
# wasm/, versions/<target>.json.
#
# Builds come from the rolling `continuous` release of xanatoo/xanatoo,
# where each target is replaced only when its own build succeeds. A target
# the release lacks (or that fails to download) is copied from the live
# site instead, so one missing build never takes a download offline.
set -euo pipefail

dir=$1
release=${XANATOO_RELEASE:-https://github.com/xanatoo/xanatoo/releases/download/continuous}
site=${XANATOO_SITE:-https://xanatoo.github.io}
mkdir -p "$dir/versions"

get() { curl -fsSL --retry 3 -o "$2" "$1"; }

# target  release asset        live-site path
targets=(
  "android xanatoo.apk         downloads/xanatoo.apk"
  "r36s    xanatoo-r36s.zip    downloads/r36s/xanatoo.zip"
  "win64   xanatoo-win64.zip   downloads/xanatoo-win64.zip"
  "win32   xanatoo-win32.zip   downloads/xanatoo-win32.zip"
  "wasm    xanatoo-wasm.tar.gz wasm/"
)

from_release() {
  local target=$1 asset=$2 tmp
  tmp=$(mktemp -d)
  get "$release/$target.json" "$tmp/$target.json" || { rm -rf "$tmp"; return 1; }
  get "$release/$asset" "$tmp/$asset" || { rm -rf "$tmp"; return 1; }
  if [ "$target" = wasm ]; then
    mkdir "$tmp/wasm"
    tar -C "$tmp/wasm" -xzf "$tmp/$asset" || { rm -rf "$tmp"; return 1; }
    rm -rf "$dir/wasm"; mv "$tmp/wasm" "$dir/wasm"
  else
    mv "$tmp/$asset" "$dir/$asset"
  fi
  mv "$tmp/$target.json" "$dir/versions/$target.json"
  rm -rf "$tmp"
}

from_site() {
  local target=$1 asset=$2 path=$3
  if [ "$target" = wasm ]; then
    mkdir -p "$dir/wasm"
    for f in index.html xanatoo.js xanatoo.wasm xanatoo.data; do
      get "$site/wasm/$f" "$dir/wasm/$f"
    done
  else
    get "$site/$path" "$dir/$asset"
  fi
  get "$site/downloads/versions/$target.json" "$dir/versions/$target.json" \
    || legacy_version "$target" > "$dir/versions/$target.json"
}

# Sites deployed before versions/ existed built every file from one
# revision, the one their Android update manifest names.
legacy_version() {
  curl -fsSL --retry 3 "$site/downloads/android-update.json" \
    | jq --arg t "$1" '{target: $t, version: .versionName, lastModified: .versionCode}' \
    || jq -n --arg t "$1" '{target: $t, version: "unknown"}'
}

failed=0
for t in "${targets[@]}"; do
  read -r target asset path <<<"$t"
  if from_release "$target" "$asset"; then
    echo "$target: release, $(jq -r .version "$dir/versions/$target.json")"
  elif from_site "$target" "$asset" "$path"; then
    echo "::warning::$target: not on the release, kept the live site's copy"
  else
    echo "::error::$target: neither the release nor the live site has it"
    failed=1
  fi
done
exit $failed
