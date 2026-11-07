# SPDX-FileCopyrightText: 2026 Ingo Ruhnke <grumbel@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# xanatoo website: one static page, Android/R36S/Windows downloads and a
# playable WebAssembly edition, all from the xanatoo flake.
#
#   nix build          # → result/ (index.html, images/, downloads/)
#   nix run .#serve    # local preview
#
{
  description = "xanatoo website (downloads built from the xanatoo flake)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # git+https, not github: only a git fetch carries the commit count the
    # version (<VERSION>.<count>+g<rev>) is made of.
    xanatoo.url = "git+https://github.com/Grumbel/xanatoo";
    xanatoo.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, xanatoo }:
    # x86_64-linux: Android, R36S, Win32/64 and wasm cross builds are hosted here.
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        app = xanatoo.packages.${system};
        version = app.xanatoo-unwrapped.version;

        site = pkgs.runCommand "xanatoo-site" { } ''
          mkdir -p $out/downloads/r36s $out/wasm
          substitute ${./index.html} $out/index.html --subst-var-by version ${version}
          cp -r ${./images} $out/images

          # Stable file names, so links never change (the version is on the page).
          cp -v ${app.xanatoo-android}/*.apk $out/downloads/xanatoo.apk
          # Same commit timestamp used for the APK Android versionCode.
          cat > $out/downloads/android-update.json <<'EOF'
          {"versionCode": ${toString (xanatoo.lastModified or 1)}, "versionName": "${version}"}
          EOF
          # PortMaster expects the zip under the name its port.json gives.
          cp -v ${app.xanatoo-r36s-portmaster-zip}/xanatoo.zip $out/downloads/r36s/xanatoo.zip
          cp -v ${app.xanatoo-win32-zip}/*.zip $out/downloads/xanatoo-win32.zip
          cp -v ${app.xanatoo-win64-zip}/*.zip $out/downloads/xanatoo-win64.zip

          # The generated Emscripten index.html references relative .js,
          # .wasm and .data files, so preserve the entire site under /wasm/.
          cp -r ${app.xanatoo-wasm}/. $out/wasm/
          for asset in index.html xanatoo.js xanatoo.wasm xanatoo.data; do
            test -s "$out/wasm/$asset"
          done
          chmod -R u+w $out
        '';

        serveApp = {
          type = "app";
          program = toString (pkgs.writeShellScript "serve-xanatoo-site" ''
            export PKG="${site}"
            exec ${./scripts/serve.sh}
          '');
        };
      in {
        packages = { default = site; inherit site; };
        apps = { default = serveApp; serve = serveApp; };
      });
}
