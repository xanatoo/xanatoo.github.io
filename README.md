# xanatoo website

Static site for [xanatoo](https://github.com/xanatoo/xanatoo).
The landing page is deliberately typeset like an article, with a concise
overview of the current editor, passage model, supported readers, and a
hands-on tour. Feature claims should track the main repository's `README.md`,
`AGENTS.md` and `TODO.md`; do not describe planned passage or revision
features as already available.

- Deploy (`.github/workflows/pages.yml`): `scripts/fetch-builds.sh` takes
  every download from xanatoo's rolling
  [`continuous` release](https://github.com/xanatoo/xanatoo/releases/tag/continuous),
  `scripts/assemble.sh` lays out `index.html`, `images/`, `downloads/` and
  `wasm/`, and the result goes to GitHub Pages (Settings → Pages → Source:
  GitHub Actions). Nothing is compiled; a run takes about a minute.
- xanatoo's `artifacts.yml` builds Android, R36S, Win32, Win64 and wasm as
  independent jobs on every push to master. Each successful job replaces
  only its own release assets and triggers this deploy, so a download is live
  minutes after its build; a failed target keeps its previous build (and the
  page shows each file's version). A target missing from the release is
  copied from the live site. The trigger needs the xanatoo repository secret
  `SITE_DISPATCH_TOKEN` (fine-grained token for this repository, "Actions:
  read and write"); without it the site still updates on its own pushes and
  nightly.
- `flake.nix` builds the same site locally, with every download built by Nix
  from the locked xanatoo input, through the same `assemble.sh`.
- Linux / Apple Silicon macOS are served as `nix run github:xanatoo/xanatoo`
  instructions. Win32/Win64 packages and a playable WASM preview use the
  feature-limited offline profile; their limitations are stated on the page.

The page also states the current experimental-network caveat: OpenSSL and
Mbed TLS clients do not yet verify peer certificates. Update that warning
when certificate verification is implemented in the application.

```bash
scripts/fetch-builds.sh builds && scripts/assemble.sh builds site   # as CI does
nix build            # result/index.html, result/downloads/*.zip, result/wasm/…
nix run .#serve      # preview on http://127.0.0.1:8765/ (XANATOO_SITE_PORT)

# against a local checkout instead of GitHub
nix build --override-input xanatoo git+file://$HOME/projects/xanatoo/trunk/xanatoo
```

Site scaffolding: use freely. xanatoo itself is GPL-3.0-or-later.
