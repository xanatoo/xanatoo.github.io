# xanatoo website

Static site for [xanatoo](https://github.com/Grumbel/xanatoo).

- `flake.nix` pulls the Android APK and the R36S PortMaster zip from the
  xanatoo flake and assembles `index.html`, `images/` and `downloads/` into
  one store path; the version on the page is the flake's own.
- `.github/workflows/pages.yml` runs `nix flake update xanatoo` and
  `nix build` on every push and nightly, and deploys `result/` to GitHub Pages
  (Settings → Pages → Source: GitHub Actions).
- Linux / macOS are served as `nix run github:Grumbel/xanatoo` instructions;
  there is no Windows build yet.

```bash
nix build            # result/index.html result/downloads/xanatoo.apk …
nix run .#serve      # preview on http://127.0.0.1:8765/ (XANATOO_SITE_PORT)

# against a local checkout instead of GitHub
nix build --override-input xanatoo git+file://$HOME/projects/xanatoo/trunk/xanatoo
```

Site scaffolding: use freely. xanatoo itself is GPL-3.0-or-later.
