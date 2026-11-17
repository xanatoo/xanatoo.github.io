# xanatoo.github.io

Deploy-only repository for <https://xanatoo.github.io/>. The page sources,
scripts and the Nix outputs that assemble the site live in the main
repository under [`website/`](https://github.com/xanatoo/xanatoo/tree/master/website)
and [`nix/site.nix`](https://github.com/xanatoo/xanatoo/blob/master/nix/site.nix);
the workflow notes are in its `docs/dev/PLATFORM.md`.

`.github/workflows/pages.yml` runs

```bash
nix run github:xanatoo/xanatoo#site-from-release -- site
```

and deploys `site/` to GitHub Pages (Settings → Pages → Source: GitHub
Actions). It is started by xanatoo's CI each time a download has been
published, by page edits there, and nightly.
