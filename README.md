# xanatoo website

Static site for [xanatoo](https://github.com/Grumbel/xanatoo).
The landing page is deliberately typeset like an article, with a concise
overview of the current editor, passage model, supported readers, and a
hands-on tour. Feature claims should track the main repository's `README.md`,
`AGENTS.md` and `TODO.md`; do not describe planned passage or revision
features as already available.

- `flake.nix` pulls the Android APK, R36S PortMaster zip, Win32/Win64 ZIPs,
  and WebAssembly site from the xanatoo flake. It assembles `index.html`,
  `images/`, `downloads/` and `wasm/` into one store path; the version on the
  page is the flake's own.
- `.github/workflows/pages.yml` runs `nix flake update xanatoo` and
  `nix build` on every push and nightly, and deploys `result/` to GitHub Pages
  (Settings → Pages → Source: GitHub Actions).
- Linux / Apple Silicon macOS are served as `nix run github:Grumbel/xanatoo`
  instructions. Win32/Win64 packages and a playable WASM preview use the
  feature-limited offline profile; their limitations are stated on the page.
- The website's xanatoo input must contain the portable flake outputs
  (`xanatoo-win32-zip`, `xanatoo-win64-zip`, `xanatoo-wasm`). Publish the main
  xanatoo repository first, then let the website workflow update its lock.

The page also states the current experimental-network caveat: OpenSSL and
Mbed TLS clients do not yet verify peer certificates. Update that warning
when certificate verification is implemented in the application.

```bash
nix build            # result/index.html, result/downloads/*.zip, result/wasm/…
nix run .#serve      # preview on http://127.0.0.1:8765/ (XANATOO_SITE_PORT)

# against a local checkout instead of GitHub
nix build --override-input xanatoo git+file://$HOME/projects/xanatoo/trunk/xanatoo
```

Site scaffolding: use freely. xanatoo itself is GPL-3.0-or-later.
