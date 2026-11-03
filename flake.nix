# SPDX-FileCopyrightText: 2026 Ingo Ruhnke <grumbel@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# xanatoo website: one static page plus the downloadable builds (Android,
# R36S) from the xanatoo flake, deployed to GitHub Pages.
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
    # x86_64-linux only: the Android SDK and NDK are not packaged elsewhere.
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        app = xanatoo.packages.${system};
        version = app.xanatoo-unwrapped.version;

        site = pkgs.runCommand "xanatoo-site" { } ''
          mkdir -p $out/downloads/r36s
          substitute ${./index.html} $out/index.html --subst-var-by version ${version}
          cp -r ${./images} $out/images

          # Stable file names, so links never change (the version is on the page).
          cp -v ${app.xanatoo-android}/*.apk $out/downloads/xanatoo.apk
          # PortMaster expects the zip under the name its port.json gives.
          cp -v ${app.xanatoo-r36s-portmaster-zip}/xanatoo.zip $out/downloads/r36s/xanatoo.zip
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
