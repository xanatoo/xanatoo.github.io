# SPDX-FileCopyrightText: 2026 Ingo Ruhnke <grumbel@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# xanatoo website: one static page, Android/R36S/Windows downloads and a
# playable WebAssembly edition.
#
# The deployed site is assembled in CI from xanatoo's rolling release
# (scripts/fetch-builds.sh + scripts/assemble.sh). This flake builds the
# same site with every download built from the locked xanatoo input:
#
#   nix build          # → result/ (index.html, images/, downloads/, wasm/)
#   nix run .#serve    # local preview
#
{
  description = "xanatoo website (downloads built from the xanatoo flake)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # git+https, not github: only a git fetch carries the commit count the
    # version (<VERSION>.<count>+g<rev>) is made of.
    xanatoo.url = "git+https://github.com/xanatoo/xanatoo";
    # xanatoo.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, xanatoo }:
    # x86_64-linux: Android, R36S, Win32/64 and wasm cross builds are hosted here.
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        app = xanatoo.packages.${system};
        version = app.xanatoo-unwrapped.version;

        # Same layout as CI's fetch-builds.sh, all from one xanatoo revision.
        builds = pkgs.runCommand "xanatoo-site-builds" { } ''
          mkdir -p $out/versions $out/wasm
          cp -v ${app.xanatoo-android}/*.apk $out/xanatoo.apk
          cp -v ${app.xanatoo-r36s-portmaster-zip}/xanatoo.zip $out/xanatoo-r36s.zip
          cp -v ${app.xanatoo-win32-zip}/*.zip $out/xanatoo-win32.zip
          cp -v ${app.xanatoo-win64-zip}/*.zip $out/xanatoo-win64.zip
          cp -r ${app.xanatoo-wasm}/. $out/wasm/
          for t in android r36s win32 win64 wasm; do
            cat > $out/versions/$t.json <<EOF
          {"target": "$t", "version": "${version}", "rev": "${xanatoo.rev or ""}",
           "revCount": ${toString (xanatoo.revCount or 0)},
           "lastModified": ${toString (xanatoo.lastModified or 1)}}
          EOF
          done
        '';

        site = pkgs.runCommand "xanatoo-site" { nativeBuildInputs = [ pkgs.jq ]; } ''
          bash ${./scripts/assemble.sh} ${builds} $out ${./.}
        '';

        serveApp = {
          type = "app";
          program = toString (pkgs.writeShellScript "serve-xanatoo-site" ''
            export PKG="${site}"
            exec ${./scripts/serve.sh}
          '');
        };
      in {
        packages = { default = site; inherit site builds; };
        apps = { default = serveApp; serve = serveApp; };
      });
}
